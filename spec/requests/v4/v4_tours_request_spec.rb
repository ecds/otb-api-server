# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('V4::Tours', type: :request) do
  describe 'GET /:tenant/v4/public/tours' do
    let(:tour_set) { create(:tour_set) }
    let(:tenant) { tour_set.subdir }

    let!(:published_count) do
      Apartment::Tenant.switch!(tenant)
      create(:tour, published: true)
      create(:tour, published: true)
      create(:tour, published: false)
      begin
        Tour.search_index.delete
      rescue StandardError
        nil
      end
      Tour.reindex
      Tour.published.count
    end

    before do
      get "/#{tenant}/v4/public/tours", headers: { 'HTTP_USER_AGENT': 'bot' }
    end

    it 'returns only published tours' do
      expect(v4_json.size).to(eq(published_count))
    end

    it 'returns status code 200' do
      expect(response).to(have_http_status(200))
    end
  end
end
