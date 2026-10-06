# frozen_string_literal: true

# Model class for connecting stops to tours.
class TourStop < ApplicationRecord
  belongs_to :tour
  belongs_to :stop
  belongs_to :map_icon, optional: true

  validates :position, presence: true

  before_create :set_icon_color
  before_validation :set_position

  delegate :slug, to: :stop

  def next
    ts = self.class.where(tour_id: tour_id).where(position: position + 1).first
    ts.presence
  end

  # Used for UIkit's Sticky component on the desktop vew. The media is sticky when scrolling until
  # the next stop comes along.
  def next_slug
    self.next&.stop&.slug
  end

  def previous
    ts = self.class.where(tour_id: tour_id).where(position: position - 1).first
    ts.presence
  end

  def previous_slug
    previous&.stop&.slug
  end

  def search_data
    search_data_with_neighbors(prev_stop: previous&.stop, next_stop: self.next&.stop)
  end

  def search_data_with_neighbors(prev_stop:, next_stop:)
    {
      next: next_stop && { id: next_stop.id, slug: next_stop.slug, title: next_stop.title },
      position:,
      previous: prev_stop && { id: prev_stop.id, slug: prev_stop.slug, title: prev_stop.title },
      relation_id: id,
      icon_color:,
      **stop.search_data,
      # After the stop's own data so these override it. A stop with no icon
      # of its own in this tour falls back to the tour's icon.
      map_icon: effective_map_icon&.original_image_url,
      map_icon_custom: map_icon_id.present?,
    }
  end

  def effective_map_icon
    map_icon || tour&.map_icon
  end

  private

  def set_position
    return if tour.nil?

    self.position = position || tour.stops.length + 1
  end

  def set_icon_color
    self.icon_color = tour.icon_color
  end
end
