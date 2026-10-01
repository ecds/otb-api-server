# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(V4::Admin::UsersController, type: :controller) do
  describe 'GET #index' do
    it 'returns 401 when unauthenticated' do
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(response).to(have_http_status(:unauthorized))
    end

    it 'returns 401 when authenticated but not super' do
      user = create(:user, super: false)
      signed_cookie(user)
      tour_set = create(:tour_set)
      get :index, params: { tenant: tour_set.subdir }
      expect(response).to(have_http_status(:unauthorized))
    end

    it 'returns 401 and list of users when authenticated as current tenant admin' do
      user = create(:user, super: false)
      signed_cookie(user)
      tour_set = create(:tour_set)
      user.tour_sets << tour_set
      Apartment::Tenant.switch!(tour_set.subdir)
      get :index, params: { tenant: tour_set.subdir }
      expect(response).to(have_http_status(:unauthorized))
    end

    it 'returns 200 and list of users when authenticated as super' do
      create(:user, display_name: nil) # Ensures the sort_by works
      user = create(:user, super: true)
      signed_cookie(user)
      tour_set = create(:tour_set)
      get :index, params: { tenant: tour_set.subdir }
      expect(response).to(have_http_status(:ok))
      expect(v4_json.count).to(eq(User.count))
    end

    it 'returns 401 when bad credentials' do
      tour_set = create(:tour_set)
      invalid_signed_cooke
      get :index, params: { tenant: tour_set.subdir }
      expect(response.status).to(eq(401))
    end
  end

  describe 'GET #show' do
    it 'returns 200 and current user when authenticated and me parameter is present' do
      user = create(:user, super: false)
      User.reindex
      signed_cookie(user)
      get :show, params: { tenant: 'public' }
      expect(response).to(have_http_status(:ok))
      expect(v4_json[:email]).to(eq(user.email))
    end

    it 'returns 401 when unauthenticated and me parameter is present' do
      get :show, params: { tenant: 'public' }
      expect(response.status).to(eq(401))
    end

    it 'returns 401 when bad credentials and me parameter is present' do
      invalid_signed_cooke
      get :show, params: { tenant: 'public' }
      expect(response.status).to(eq(401))
    end
  end
end
