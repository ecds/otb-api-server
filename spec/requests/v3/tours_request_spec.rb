# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('V3::Tours', type: :request) do
  describe 'GET /:tenant/tours' do
    let(:tour_set) { create(:tour_set) }
    let!(:setup) do
      Apartment::Tenant.switch!(tour_set.subdir)
      create(:tour, published: true)
      create(:tour, published: true)
      create(:tour, published: false)
      begin
        Tour.search_index.delete
      rescue StandardError
        nil
      end
      Tour.reindex
    end

    before { get "/#{tour_set.subdir}/tours", headers: { 'HTTP_USER_AGENT': 'bot' } }

    it 'returns only published tours' do
      Apartment::Tenant.switch!(tour_set.subdir)
      expect(json.size).to(eq(Tour.published.count))
    end

    it 'returns status code 200' do
      expect(response).to(have_http_status(:ok))
    end
  end
end
