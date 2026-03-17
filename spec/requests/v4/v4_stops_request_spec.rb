# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V4::Stops', type: :request do
  describe 'GET /:tenant/v4/public/stops' do
    before {
      Apartment::Tenant.switch! TourSet.last.subdir
      get "/#{Apartment::Tenant.current}/v4/public/stops", headers: { 'HTTP_USER_AGENT': 'bot' }
    }

    # it 'returns only published stops' do
    #   puts response.status
    #   expect(v4_json.size).to eq(Stop.all.filter(&:published).count)
    # end

    # it 'returns status code 200' do
    #   expect(response).to have_http_status(200)
    # end
  end
end
