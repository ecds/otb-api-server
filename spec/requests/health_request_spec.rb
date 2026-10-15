# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('Rails::HealthController', type: :request) do
  describe 'GET /health' do
    before do
      Apartment::Tenant.switch!(TourSet.last.subdir)
      get '/health', headers: { 'HTTP_USER_AGENT': 'bot' }
    end

    it 'returns status code 200' do
      expect(response).to(have_http_status(:ok))
    end
  end
end
