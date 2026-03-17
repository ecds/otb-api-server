class AccessRequest < ApplicationRecord
  after_update :authorize
  validates :tour_set, uniqueness: { scope: [ :user, :tour ] }
  belongs_to :user

  def search_data
    {
      id:,
      user: user.display_name,
      email: user.email,
      site: TourSet.find_by(subdir: tour_set).name,
      tour: requested_tour&.title || nil,
      date: created_at.strftime("%B %d, %Y")
    }
  end

  private

  def notify
  end

  def authorize
    if approved
      Apartment::Tenant.switch! tour_set

      user.tours << requested_tour unless requested_tour.nil?
      user.tour_sets << TourSet.find_by(subdir: tour_set) if tour.nil?
    end

    self.delete
  end

  def requested_tour
    Tour.find(tour) if tour.present?
  end
end
