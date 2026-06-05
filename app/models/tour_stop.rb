# frozen_string_literal: true

# Model class for connecting stops to tours.
class TourStop < ApplicationRecord
  belongs_to :tour
  belongs_to :stop

  validates :position, presence: true

  # before_save :_ensure_stop_slug
  before_validation :_set_position

  def slug
    stop.slug
  end

  def next
    ts = self.class.where(tour_id: tour_id).where(position: position + 1).first
    ts.present? ? ts : nil
  end

  # Used for UIkit's Sticky component on the desktop vew. The media is sticky when scrolling until
  # the next stop comes along.
  def next_slug
    self.next.nil? ? nil : self.next.stop.slug
  end

  def previous
    ts = self.class.where(tour_id: tour_id).where(position: position - 1).first
    ts.present? ? ts : nil
  end

  def previous_slug
    previous.nil? ? nil : previous.stop.slug
  end

  def search_data
    {
      next: if self.next.present?
              {
                id: self.next.stop.id,
                slug: self.next.stop.slug,
                title: self.next.stop.title,
              }
            end,
      position: position,
      previous: if previous.present?
                  {
                    id: previous.stop.id,
                    slug: previous.stop.slug,
                    title: previous.stop.title,
                  }
                end,
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
