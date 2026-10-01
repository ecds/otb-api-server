# frozen_string_literal: true

# Model class for connecting stops to tours.
class TourStop < ApplicationRecord
  belongs_to :tour
  belongs_to :stop

  validates :position, presence: true

  # before_save :_ensure_stop_slug
  before_validation :_set_position

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
      **stop.search_data,
    }
  end

  private

  def _set_position
    return if tour.nil?

    self.position = position || tour.stops.length + 1
  end

  # def _ensure_stop_slug
  #   new_slug = StopSlug.find_or_create_by(slug: self.stop.slug, tour: self.tour)
  #   new_slug.stop = self.stop
  #   new_slug.save
  # end
end
