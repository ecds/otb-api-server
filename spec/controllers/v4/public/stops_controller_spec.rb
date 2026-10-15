# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(V4::Public::StopsController, type: :controller) do
  let(:tour_set) { create(:tour_set) }
  let(:published_tour) { create(:tour, published: true) }
  let(:unpublished_tour) { create(:tour, published: false) }

  before { Apartment::Tenant.switch!(tour_set.subdir) }

  describe 'GET #index' do
    it 'returns 401 when unauthenticated' do
      get :index, params: { tenant: tour_set.subdir }
      expect(response).to(have_http_status(:unauthorized))
    end

    it 'returns stops when authenticated as super admin' do
      user = create(:user, super: true)
      create(:stop, tours: [published_tour])
      signed_cookie(user)
      get :index, params: { tenant: tour_set.subdir }
      expect(response).to(have_http_status(:ok))
    end
  end

  describe 'GET #show' do
    it 'returns 404 when slug does not exist' do
      get :show, params: { tenant: tour_set.subdir, slug: 'nonexistent' }
      expect(response).to(have_http_status(:not_found))
    end

    it 'returns 404 when stop exists but is unpublished' do
      stop = create(:stop, tours: [unpublished_tour])
      get :show, params: { tenant: tour_set.subdir, slug: stop.slug }
      expect(response).to(have_http_status(:not_found))
    end

    it 'returns stop data when stop is published' do
      stop = create(:stop, tours: [published_tour])
      get :show, params: { tenant: tour_set.subdir, slug: stop.slug }
      expect(response).to(have_http_status(:ok))
      expect(v4_json[:title]).to(eq(stop.title))
    end
  end
end
