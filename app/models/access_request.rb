# frozen_string_literal: true

class AccessRequest < ApplicationRecord
  after_update :authorize
  validates :tour_set, uniqueness: { scope: [:user] }
  belongs_to :user
  belongs_to :tour_set

  def search_data
    {
      id:,
      user: user.display_name,
      email: user.email,
      site: tour_set.name,
      tours: requested_tours.map(&:title) || nil,
      date: created_at.strftime('%B %d, %Y'),
    }
  end

  def requested_tours
    return [] if tour_ids.nil? || tour_ids.empty?

    Apartment::Tenant.switch!(tour_set.subdir)
    Tour.find(tour_ids)
  end

  private

  def authorize
    if approved
      user.tours << requested_tours unless requested_tours.empty?
      user.tour_sets << tour_set if requested_tours.empty?
    end

    delete
  end
end
