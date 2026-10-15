# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('V4::Public::Stops', type: :request) do
  let(:tour_set) { create(:tour_set) }

  describe 'GET /:tenant/v4/public/stops' do
    it 'returns 401 when unauthenticated' do
      get "/#{tour_set.subdir}/v4/public/stops"
      expect(response).to(have_http_status(:unauthorized))
    end
  end

  describe 'GET /:tenant/v4/public/stops/:slug' do
    it 'returns 404 when stop slug does not exist' do
      get "/#{tour_set.subdir}/v4/public/stops/nonexistent-slug"
      expect(response).to(have_http_status(:not_found))
      expect(v4_json[:errors]).to(include('Not found'))
    end

    it 'returns stop data when stop belongs to a published tour' do
      Apartment::Tenant.switch!(tour_set.subdir)
      stop = create(:stop)
      create(:tour, published: true, stops: [stop])
      get "/#{tour_set.subdir}/v4/public/stops/#{stop.slug}"
      expect(response).to(have_http_status(:ok))
    end
  end
end
