# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V4::Tours', type: :request do
  describe 'GET /:tenant/v4/public/tours' do
    before {
      Apartment::Tenant.switch! TourSet.last.subdir
      Tour.reindex
      get "/#{Apartment::Tenant.current}/v4/public/tours", headers: { 'HTTP_USER_AGENT': 'bot' }
    }

    it 'returns only published tours' do
      expect(json.size).to eq(Tour.published.count)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end
end
