# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(V4::Admin::TourSetsController, type: :controller) do
  describe 'GET #index' do
    it 'returns 401 when unauthenticated' do
      get :index, params: { tenant: 'public' }
      expect(response.status).to(eq(401))
      expect(v4_json[:error]).to(eq('unauthorized'))
    end

    it 'returns all TourSets when authenticated as super' do
      user = create(:user, super: true)
      signed_cookie(user)
      get :index, params: { tenant: 'public' }
      expect(response.status).to(eq(200))
      expect(v4_json.count).to(eq(TourSet.count))
    end

    it 'returns all TourSets (not just assigned) when authenticated as non-super' do
      # Any authenticated user can see all TourSets so they can request access
      user = create(:user, super: false)
      user.tour_sets << create_list(:tour_set, 3)
      signed_cookie(user)
      get :index, params: { tenant: 'public' }
      expect(response.status).to(eq(200))
      expect(v4_json.count).to(eq(TourSet.count))
      expect(v4_json.count).to(be > user.tour_sets.count)
    end
  end

  describe 'GET #show' do
    it 'returns 401 when unauthenticated' do
      tour_set = create(:tour_set)
      get :show, params: { tenant: 'public', slug: tour_set.subdir }
      expect(response.status).to(eq(401))
    end

    it 'returns 200 and a tour set when authenticated as super' do
      user = create(:user, super: true)
      signed_cookie(user)
      tour_set = create(:tour_set)
      get :show, params: { tenant: 'public', slug: tour_set.subdir }
      expect(response.status).to(eq(200))
      expect(v4_json[:name]).to(eq(tour_set.name))
    end

    it 'returns 200 a tour set when authenticated as site owner' do
      user = create(:user, super: false)
      tour_set = create(:tour_set)
      user.tour_sets << tour_set
      signed_cookie(user)
      get :show, params: { tenant: 'public', slug: tour_set.subdir }
      expect(response.status).to(eq(200))
      expect(v4_json[:name]).to(eq(tour_set.name))
    end

    it 'returns 401 when authenticated as site owner but requesting a different site' do
      user = create(:user, super: false)
      owned_tour_set = create(:tour_set)
      other_tour_set = create(:tour_set)
      user.tour_sets << owned_tour_set
      signed_cookie(user)
      get :show, params: { tenant: 'public', slug: other_tour_set.subdir }
      expect(response.status).to(eq(401))
    end

    it 'lists all tours in the set' do
      user = create(:user, super: true)
      signed_cookie(user)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch!(tour_set.subdir)
      create_list(:tour, 3, published: true)
      create_list(:tour_with_stops, 2, published: false)
      Apartment::Tenant.reset
      get :show, params: { tenant: 'public', slug: tour_set.subdir }
      Apartment::Tenant.switch!(tour_set.subdir)
      expect(v4_json[:tours].count).to(eq(Tour.count))
    end

    it 'includes tour authors in response' do
      user = create(:user, super: true)
      signed_cookie(user)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour1 = create(:tour)
      tour2 = create(:tour)
      user1 = create(:user, tours: [tour1, tour2])
      user2 = create(:user, display_name: nil, email: 'rwoodruf@emory.edu', tours: [tour2])
      Apartment::Tenant.reset
      get :show, params: { tenant: 'public', slug: tour_set.subdir }
      expect(v4_json[:tour_authors].select { |ta| ta[:user] == user1.display_name }.count).to(eq(2))
      expect(v4_json[:tour_authors].select { |ta| ta[:user] == user2.email }.count).to(eq(1))
    end

    it 'returns no content when user is a tour editor within the site (not a site admin)' do
      tour_set = create(:tour_set)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      user = create(:user, super: false, tours: [tour])
      signed_cookie(user)
      Apartment::Tenant.reset
      get :show, params: { tenant: 'public', slug: tour_set.subdir }
      expect(response).to(have_http_status(:no_content))
    end
  end
end
