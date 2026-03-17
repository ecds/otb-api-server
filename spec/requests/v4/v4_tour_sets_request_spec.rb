# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V4::TourSets', type: :request do
  describe 'GET /:tenant/v4/public/tours' do
    before {
      Apartment::Tenant.switch! 'public'
      TourSet.reindex
      get "/public/v4/public/tour-sets", headers: { 'HTTP_USER_AGENT': 'bot' }
    }

    it 'returns only published tours' do
      Apartment::Tenant.switch! 'public'
      expect(v4_json.size).to eq(TourSet.all.filter { |ts| ts.published_tours.count > 0 }.count)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end
end
