class MapOverlay < MediumBaseRecord
  before_create :set_initial_bounds

  belongs_to :tour, optional: true
  belongs_to :stop, optional: true

  def image_url
    return nil unless file.attached?

    file.service_url
  end

  def set_initial_bounds
    if tour
      self.south = self.tour.bounds[:south]
      self.north = self.tour.bounds[:north]
      self.east = self.tour.bounds[:east]
      self.west = self.tour.bounds[:west]
    end
  end
end
