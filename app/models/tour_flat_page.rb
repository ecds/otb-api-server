# frozen_string_literal: true

# /app/models/tour_mode.rb
class TourFlatPage < ApplicationRecord
  belongs_to :tour
  belongs_to :flat_page

  before_validation do
    self.position = position || tour.tour_flat_pages.count + 1
  end

  def search_data
    {
      position: position,
      relation_id: id,
      **flat_page.search_data,
    }
  end
end
