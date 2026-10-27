# frozen_string_literal: true

# Whether a user may create, update, or delete a record through the generic
# admin endpoint. Each record is traced back to the tours it belongs to, and
# TourAccess decides from there. Site-level models are for site admins.
class CrudAccess
  MODELS = [
    'flat_page',
    'map_icon',
    'map_overlay',
    'medium',
    'stop',
    'stop_medium',
    'tour',
    'tour_author',
    'tour_flat_page',
    'tour_medium',
    'tour_mode',
    'tour_set',
    'tour_set_admin',
    'tour_stop',
    'user',
    'voice_over',
  ].freeze

  # Records that are made first and linked to a tour after.
  STANDALONE = [Stop, Medium, FlatPage, MapIcon, MapOverlay].freeze

  # Signed out, the auth engine gives an unsaved User.
  def initialize(user)
    @user = user&.persisted? ? user : nil
  end

  class << self
    def model?(name)
      MODELS.include?(name.to_s)
    end
  end

  def create?(record)
    return false if @user.nil?
    return site_admin_for?(record) if site_level?(record)
    return false if record.is_a?(Tour)
    return true if admin?

    tours = tours_for(record)
    return author_here? if tours.empty? && STANDALONE.include?(record.class)

    tours.any? && tours.all? { |tour| access(tour).edit? }
  end

  def update?(record, changes = {})
    return false if @user.nil?
    return record == @user || @user.super if record.is_a?(User)
    return site_admin_for?(record) if site_level?(record)
    return true if admin?

    if record.is_a?(Tour)
      tour_access = access(record)
      return false unless tour_access.edit?
      return true unless changes.key?('published') || changes.key?(:published)

      return tour_access.publish?
    end

    tours = tours_for(record)
    return owner_or_admin?(record) if tours.empty?

    tours.any? { |tour| access(tour).edit? }
  end

  def destroy?(record)
    return false if @user.nil?
    return false if record.is_a?(User)
    return site_admin_for?(record) if site_level?(record)
    return true if admin?
    return access(record).delete_tour? if record.is_a?(Tour)

    case record
    when TourStop then access(record.tour).remove?(record.stop)
    when TourMedium then access(record.tour).remove?(record.medium)
    when StopMedium then record.stop.tours.all? { |tour| access(tour).remove?(record.medium) }
    when Stop, Medium
      tours = tours_for(record)
      tours.empty? ? owner_or_admin?(record) : tours.all? { |tour| access(tour).remove?(record) }
    else
      tours = tours_for(record)
      tours.empty? ? admin? : tours.any? { |tour| access(tour).edit? }
    end
  end

  private

  def admin?
    @user.current_tenant_admin?
  end

  # Has any tour on this site, so may start new stops and media for it.
  def author_here?
    admin? || @user.tours.exists?
  end

  def owner_or_admin?(record)
    admin? || (record.respond_to?(:created_by_id) && record.created_by_id.present? && record.created_by_id == @user.id)
  end

  # A Tour Admin of that tour set, whichever tenant the request came in on.
  def site_admin_for?(record)
    return true if @user.super

    tour_set = case record
    when TourSet then record
    when TourAuthor then TourSet.find_by(subdir: Apartment::Tenant.current)
    else record.tour_set
    end
    return false if tour_set.nil? || tour_set.new_record?

    @user.tour_set_admins.exists?(tour_set:, role: Role.find_by(title: 'Tour Admin'))
  end

  def site_level?(record)
    record.is_a?(TourSet) || record.is_a?(TourSetAdmin) || record.is_a?(TourAuthor)
  end

  def access(tour)
    (@access ||= {})[tour.id] ||= TourAccess.new(@user, tour)
  end

  def tours_for(record)
    tours = case record
    when TourStop, TourMedium, TourMode, TourFlatPage then [record.tour]
    when Stop, FlatPage then record.tours.to_a
    when StopMedium then record.stop&.tours.to_a
    when Medium then record.tours.to_a + record.stops.flat_map(&:tours)
    when VoiceOver, MapOverlay then record.tour ? [record.tour] : record.stop&.tours.to_a
    when MapIcon then [record.tour, *record.stop&.tours, *record.tour_stops.map(&:tour)]
    else []
    end
    tours.compact.uniq
  end
end
