# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Tour) do
  describe 'open_geographies_endpoint' do
    it 'can be saved on an allowed host' do
      tour = build(:tour, open_geographies_endpoint: 'https://og.example.org/tours/jackson')
      expect(tour).to(be_valid)
    end

    it 'cannot be saved on a host that is not allowed' do
      tour = build(:tour, open_geographies_endpoint: 'https://internal.test/tours/jackson')
      expect(tour).not_to(be_valid)
      expect(tour.errors[:open_geographies_endpoint]).to(eq(["internal.test isn't an allowed Open Geographies host."]))
    end

    it 'can be cleared' do
      tour = create(:tour, open_geographies_endpoint: 'https://og.example.org/tours/jackson')
      tour.open_geographies_endpoint = ''
      expect(tour).to(be_valid)
    end

    it "doesn't block other edits to a tour saved before the host list existed" do
      tour = create(:tour)
      # Skips validation on purpose: an endpoint saved before hosts were checked.
      tour.update_column(:open_geographies_endpoint, 'https://internal.test/tours/jackson') # rubocop:disable Rails/SkipsModelValidations
      tour.title = 'Renamed'
      expect(tour).to(be_valid)
    end
  end
end
