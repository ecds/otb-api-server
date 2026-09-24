# frozen_string_literal: true

# /app/models/tour_mode.rb
class TourFlatPage < ApplicationRecord
  belongs_to :tour
  belongs_to :flat_page

  after_create do
    self.position = tour.tour_flat_pages.length + 1
    save
  end

  def search_data
    {
      position: position,
      relation_id: id,
      **flat_page.search_data,
    }
  end
end
