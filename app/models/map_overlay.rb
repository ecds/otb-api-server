# frozen_string_literal: true

#
# Model class for map overlays.
#
class MapOverlay < MediumBaseRecord
  before_save :set_initial_bounds

  belongs_to :tour, optional: true
  belongs_to :stop, optional: true

  delegate :published, to: :tour

  def set_initial_bounds
    return if tour.nil? || tour&.bounds.nil? || (tour&.stop_count&.< 2)

    self.south = tour.bounds[:south] if south.to_f.zero?
    self.north = tour.bounds[:north] if north.to_f.zero?
    self.east = tour.bounds[:east] if east.to_f.zero?
    self.west = tour.bounds[:west] if west.to_f.zero?
  end

  def search_data
    {
      id:,
      east: east.to_f,
      image_url: http_path,
      north: north.to_f,
      south: south.to_f,
      west: west.to_f,
      rotation:,
    }
  end
end
