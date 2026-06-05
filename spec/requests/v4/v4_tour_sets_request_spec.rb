# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('V4::TourSets', type: :request) do
  describe 'GET /public/v4/public/tour-sets' do
    let!(:setup) do
      # Create tour sets: some with published tours (should appear), some without (should not)
      with_tours = create_list(:tour_set, 2)
      with_tours.each do |ts|
        Apartment::Tenant.switch!(ts.subdir)
        create(:tour_with_stops, published: true)
      end
      create(:tour_set) # no published tours — should be excluded
      Apartment::Tenant.switch!('public')
      begin
        TourSet.search_index.delete
      rescue StandardError
        nil
      end
      TourSet.reindex
    end

    before { get '/public/v4/public/tour-sets', headers: { 'HTTP_USER_AGENT': 'bot' } }

    it 'returns only tour sets that have published tours' do
      Apartment::Tenant.switch!('public')
      expected = TourSet.all.select { |ts| ts.published_tours.count > 0 }
      expect(v4_json.size).to(eq(expected.count))
    end

    it 'returns status code 200' do
      expect(response).to(have_http_status(:ok))
    end
  end
end
