# frozen_string_literal: true

class User < ActiveRecord::Base
  has_many :tour_set_admins
  has_many :tour_sets, through: :tour_set_admins
  has_many :tour_authors
  has_many :tours, through: :tour_authors

  # scope :search, -> (search) { joins(:login).where("users.display_name ILIKE '%#{search}%' OR logins.identification ILIKE '%#{search}%'")}

  #
  # Gets role for current tenant
  #
  # @return [Role] Role object
  #
  def current_tenant_admin?
    return true if self.super
    return false if tour_sets.empty?
    tour_sets.map(&:subdir).include? Apartment::Tenant.current
  end

  def provider
    return nil if login.nil?
    login.provider
  end

  def all_tours
    all = []
    TourSet.all.each do |tour_set|
      Apartment::Tenant.switch! tour_set.subdir
      next if tours.empty? || current_tenant_admin?
      Apartment::Tenant.switch! tour_set.subdir
      _tours = TourAuthor.where(user: self)
      # puts tours.ma
      all.push(_tours.map { |ta| { id: ta.tour.id, tenant: ta.tour.tenant, title: ta.tour.title } })
    end
    Apartment::Tenant.reset
    all.flatten.uniq
  end

  def login
    EcdsRailsAuthEngine::Login.find_by(user_id: self.id)
  end
end
