# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(V4::Admin::StopsController, type: :controller) do
  describe 'GET #index' do
    it 'returns 401 when unauthenticated' do
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(response.status).to(eq(401))
    end

    it 'returns 200 and list of stops when authenticated as super' do
      user = create(:user, super: true)
      signed_cookie(user)
      create_list(:stop, 4)
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(response.status).to(eq(200))
      expect(v4_json.count).to(eq(Stop.count))
    end

    it 'returns 200 and list of stops when authenticated as site owner' do
      user = create(:user, super: false)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch!(tour_set.subdir)
      create_list(:stop, 3)
      user.tour_sets << tour_set
      signed_cookie(user)
      get :index, params: { tenant: tour_set.subdir }
      expect(response.status).to(eq(200))
      expect(v4_json.count).to(eq(Stop.count))
    end

    it 'returns 200 and list of stops when authenticated as tour author' do
      user = create(:user, super: false)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      create_list(:stop, 2)
      user.tours << tour
      signed_cookie(user)
      get :index, params: { tenant: tour_set.subdir }
      expect(response.status).to(eq(200))
      expect(v4_json.count).to(eq(Stop.count))
    end

    it 'returns 401 when authenticated as site owner but requesting stops for different site' do
      user = create(:user, super: false)
      tour_sets = create_list(:tour_set, 4)
      Apartment::Tenant.switch!(tour_sets.first.subdir)
      user.tour_sets << tour_sets.last
      signed_cookie(user)
      get :index, params: { tenant: tour_sets.first.subdir }
      expect(response.status).to(eq(401))
    end

    it 'returns 200 and paginated list of stops when authenticated as site owner' do
      user = create(:user, super: false)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch!(tour_set.subdir)
      create_list(:stop, 3)
      user.tour_sets << tour_set
      signed_cookie(user)
      get :index, params: { tenant: tour_set.subdir, page: 2, per: 1 }
      expect(response.status).to(eq(200))
      expect(v4_json.count).to(eq(1))
    end
  end
end
