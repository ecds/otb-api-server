# frozen_string_literal: true

class User < ActiveRecord::Base
  include Searchable
  after_update :update_index
  has_many :tour_set_admins
  has_many :tour_sets, through: :tour_set_admins
  has_many :tour_authors
  has_many :tours, through: :tour_authors
  has_many :access_requests

  validates :email, presence: true

  # scope :search, -> (search) { joins(:login).where("users.display_name ILIKE '%#{search}%' OR logins.identification ILIKE '%#{search}%'")}

  #
  # Gets role for current tenant
  #
  # @return [Role] Role object
  #
  def current_tenant_admin?
    return true if self.super
    return false if tour_sets.empty?

    tour_sets.map(&:subdir).include?(Apartment::Tenant.current)
  end

  def preview_data
    {
      id:,
      display_name:,
      email:,
      super:,
      tour_sets: tour_set_admins.map { |tsa| { id: tsa.id, name: tsa.tour_set.name, subdir: tsa.tour_set.subdir } },
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

  private

  def as_author
    return unless persisted?

    # preserve current tenant so we can go back
    current = Apartment::Tenant.current
    all = TourSet.all.map do |ts|
      next if tour_sets.include?(ts)

      Apartment::Tenant.switch!(ts.subdir)
      tours = TourAuthor.where(user: self).map(&:tour)
      { tour_set: ts, tours: } unless tours.empty?
    end.flatten.compact
    # return to initial tenant
    Apartment::Tenant.switch!(current)
    all
  end

  def as_site_editor
    as_author.map { |t| t[:tour_set] }
  end

  def update_index
    reindex
  end

  def last_sign_in
    return if login.nil? || login.tokens.empty?

    login.tokens.order(created_at: :desc).first.created_at.strftime('%b %d, %Y')
  end
end
