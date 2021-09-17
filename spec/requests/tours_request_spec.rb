# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V3::Tours', type: :request do
  describe 'GET /:tenant/tours' do
    before {
      get "/#{Apartment::Tenant.current}/tours", headers: { 'HTTP_USER_AGENT': 'bot' }
    }

    it 'returns only published tours' do
      expect(json.size).to eq(Tour.published.count)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end
end
