# frozen_string_literal: true

#
# Model calss for map overlays.
#
class MapOverlay < MediumBaseRecord
  before_create :set_initial_bounds

  belongs_to :tour, optional: true
  belongs_to :stop, optional: true

  def published
    tour.published
  end

  def set_initial_bounds
    return if tour&.bounds.nil?

    if tour
      self.south = self.tour.bounds[:south]
      self.north = self.tour.bounds[:north]
      self.east = self.tour.bounds[:east]
      self.west = self.tour.bounds[:west]
    end
  end
end
