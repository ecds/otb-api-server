# frozen_string_literal: true

# What a user may do to one tour. Site admins and tour authors can do
# everything. Student authors can edit the tour, but can't publish or
# unpublish it, or delete it, and can remove only the stops and media they
# added, and only while the tour isn't published.
class TourAccess
  attr_reader :user, :tour

  # Signed out, the auth engine gives an unsaved User.
  def initialize(user, tour)
    @user = user&.persisted? ? user : nil
    @tour = tour
  end

  def edit?
    admin? || author.present?
  end

  def student?
    !admin? && author&.student? == true
  end

  def full?
    edit? && !student?
  end

  alias_method :publish?, :full?
  alias_method :delete_tour?, :full?

  # A stop or medium leaving the tour (unlinked or deleted).
  def remove?(record)
    return full? unless student?

    !published? && record.respond_to?(:created_by_id) && record.created_by_id.present? &&
      record.created_by_id == user.id
  end

  # Sent with the admin's copy of the tour, so it can hide what the API
  # would refuse.
  def as_json(*)
    {
      student: student?,
      publish: publish?,
      delete_tour: delete_tour?,
      removable_stop_ids: student? ? removable_ids(tour.stops) : nil,
      removable_medium_ids: student? ? removable_ids(tour_media) : nil,
    }
  end

  private

  def admin?
    user&.current_tenant_admin? == true
  end

  def author
    return if user.nil? || tour.nil?

    @author ||= TourAuthor.find_by(user:, tour:)
  end

  # As saved, so an unsaved change to `published` doesn't count.
  def published?
    tour.attribute_in_database(:published) == true
  end

  def tour_media
    Medium.where(id: tour.tour_media.select(:medium_id))
      .or(Medium.where(id: StopMedium.where(stop_id: tour.tour_stops.select(:stop_id)).select(:medium_id)))
  end

  def removable_ids(records)
    return [] if published?

    records.where(created_by_id: user.id).pluck(:id)
  end
end
