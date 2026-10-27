# frozen_string_literal: true

class User < ApplicationRecord
  include Searchable
  has_many :tour_set_admins, dependent: :destroy
  has_many :tour_sets, through: :tour_set_admins
  has_many :tour_authors, dependent: :destroy
  has_many :tours, through: :tour_authors
  has_many :access_requests, dependent: :destroy

  validates :email, presence: true

  # scope :search, -> (search) { joins(:login).where("users.display_name ILIKE '%#{search}%' OR logins.identification ILIKE '%#{search}%'")}

  #
  # Gets role for current tenant
  #
  # @return [Role] Role object
  #
  def current_tenant_admin?
    return true if self.super

    admin_role = Role.find_by(title: 'Tour Admin')
    admin_tour_sets = tour_set_admins.where(role: admin_role).map(&:tour_set)
    return false if admin_tour_sets.empty?

    admin_tour_sets.map(&:subdir).include?(Apartment::Tenant.current)
  end

  def current_tenant_tour_creator?
    return true if current_tenant_admin?

    tour_creator_role = Role.find_by(title: 'Tour Creator')
    tour_creator_sets = tour_set_admins.where(role: tour_creator_role).map(&:tour_set)
    return false if tour_creator_sets.empty?

    tour_creator_sets.map(&:subdir).include?(Apartment::Tenant.current)
  end

  def preview_data
    {
      id:,
      display_name:,
      email:,
      super:,
      tour_sets: tour_set_admins.map do |tsa|
        { id: tsa.id, name: tsa.tour_set.name, subdir: tsa.tour_set.subdir, role: tsa.role&.title }
      end,
      terms_accepted:,
      access_requests: access_requests.map(&:search_data),
      date_joined: created_at&.strftime('%b %d, %Y'),
      last_sign_in:,
    }
  end

  def search_data
    {
      **preview_data,
      current_tenant_admin: current_tenant_admin?,
      may_create_tour: current_tenant_tour_creator?,
      tours: as_author,
    }
  end

  def provider
    return if login.nil?

    login.provider
  end

  def all_tours
    all = TourSet.all.map do |tour_set|
      Apartment::Tenant.switch!(tour_set.subdir)
      next if tours.empty? || current_tenant_admin?

      Apartment::Tenant.switch!(tour_set.subdir)
      TourAuthor.where(user: self).map { |ta| { id: ta.tour.id, tenant: ta.tour.tenant, title: ta.tour.title } }
    end.flatten.uniq.compact
    Apartment::Tenant.reset
    all
  end

  def login
    EcdsRailsAuthEngine::Login.find_by(user_id: id)
  end

  # The only super user can't delete their account, or nobody could manage
  # the platform.
  def last_super?
    self.super && User.where(super: true).where.not(id:).none?
  end

  # Deletes the account and everything that only gives it access: sign-ins,
  # site roles, tour authorships on every site, and access requests. What the
  # user made (tours, stops, media, ...) is left as it is.
  def delete_account!
    transaction do
      TourSet.find_each do |tour_set|
        Apartment::Tenant.switch(tour_set.subdir) { TourAuthor.where(user_id: id).delete_all }
      rescue Apartment::TenantNotFound
        next
      end
      logins = EcdsRailsAuthEngine::Login.where(user_id: id)
      EcdsRailsAuthEngine::Token.where(login_id: logins.select(:id)).delete_all
      logins.delete_all
      destroy!
    end
  end

  private

  def as_author
    return unless persisted?

    # preserve current tenant so we can go back
    current = Apartment::Tenant.current
    all = TourSet.all.map do |ts|
      next if tour_sets.include?(ts)

      Apartment::Tenant.switch!(ts.subdir)
      authorships = TourAuthor.where(user: self).includes(:tour)
      tours = authorships.map(&:tour)
      { tour_set: ts, tours:, student_tour_ids: authorships.select(&:student).map(&:tour_id) } unless tours.empty?
    end.flatten.compact
    # return to initial tenant
    Apartment::Tenant.switch!(current)
    all
  end

  def as_site_editor
    as_author.map { |t| t[:tour_set] }
  end

  def last_sign_in
    return if login.nil? || login.tokens.empty?

    login.tokens.order(created_at: :desc).first.created_at.strftime('%b %d, %Y')
  end
end
