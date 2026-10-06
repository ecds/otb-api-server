# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(TourFlatPage, type: :model) do
  describe 'tour flat page relationship' do
    it 'adds a flat page to a tour with correct position' do
      tour = create(:tour_with_flat_pages)
      expect(tour.tour_flat_pages.last.position).to(eq(3))
      flat_page = create(:flat_page)
      tour.flat_pages << flat_page
      tour.reload
      expect(tour.tour_flat_pages.last.position).to(eq(4))
    end

    it 'keeps the position it was already has' do
      tour = create(:tour)
      expect(tour.tour_flat_pages.count).to(eq(0))
      create(:tour_flat_page, position: 5, tour:)
      tour.reload
      expect(tour.tour_flat_pages.count).to(eq(1))
      expect(tour.tour_flat_pages.first.position).to(eq(5))
    end
  end
end
