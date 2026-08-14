# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(V4::Admin::ToursController, type: :controller) do
  let(:tour_set) { create(:tour_set) }

  def clean_reindex
    begin
      Tour.search_index.delete
    rescue StandardError
      nil
    end
    Tour.reindex
  end

  describe 'GET #index' do
    it 'returns 401 when unauthenticated' do
      get :index, params: { tenant: tour_set.subdir }
      expect(response.status).to(eq(401))
    end

    it 'returns all tours when super user' do
      user = create(:user, super: true)
      signed_cookie(user)
      Apartment::Tenant.switch!(tour_set.subdir)
      create_list(:tour, 4)
      clean_reindex
      get :index, params: { tenant: tour_set.subdir }
      expect(v4_json.count).to(eq(Tour.count))
    end

    it 'returns all tours when tour set admin' do
      user = create(:user, super: false)
      Apartment::Tenant.switch!(tour_set.subdir)
      create_list(:tour, 4)
      user.tour_sets << tour_set
      signed_cookie(user)
      clean_reindex
      get :index, params: { tenant: tour_set.subdir }
      expect(v4_json.count).to(eq(Tour.count))
    end

    it 'returns only tours assigned to user' do
      user = create(:user, super: false)
      signed_cookie(user)
      Apartment::Tenant.switch!(tour_set.subdir)
      tours = create_list(:tour, 4)
      user.tours << [tours.first, tours.last]
      clean_reindex
      get :index, params: { tenant: tour_set.subdir }
      expect(v4_json.count).to(eq(2))
      expect(v4_json.count).not_to(eq(Tour.count))
    end

    it 'returns empty list when no tours' do
      user = create(:user, super: true)
      signed_cookie(user)
      Apartment::Tenant.switch!(tour_set.subdir)
      expect(Tour.count).to(be_zero)
      clean_reindex
      get :index, params: { tenant: tour_set.subdir }
      expect(v4_json.count).to(be_zero)
    end

    it 'returns list of all tours if all param is present' do
      user = create(:user, super: false)
      signed_cookie(user)
      Apartment::Tenant.switch!(tour_set.subdir)
      create_list(:tour, 3)
      clean_reindex
      get :index, params: { tenant: tour_set.subdir, all: true }
      expect(v4_json.count).to(eq(Tour.count))
      expect(v4_json.count).to(be > 0)
    end
  end

  describe 'GET #show' do
    it 'returns 401 when unauthenticated' do
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      clean_reindex
      get :show, params: { tenant: tour_set.subdir, id: tour.id }
      expect(response.status).to(eq(401))
    end

    it 'returns 200 and tour when authenticated as super' do
      user = create(:user, super: true)
      signed_cookie(user)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      clean_reindex
      get :show, params: { tenant: tour_set.subdir, id: tour.id }
      expect(response.status).to(eq(200))
      expect(v4_json[:title]).to(eq(tour.title))
    end

    it 'returns 200 a tour when authenticated as site owner' do
      user = create(:user, super: false)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      user.tour_sets << tour_set
      signed_cookie(user)
      clean_reindex
      get :show, params: { tenant: tour_set.subdir, id: tour.id }
      expect(response.status).to(eq(200))
      expect(v4_json[:title]).to(eq(tour.title))
    end

    it 'returns 200 a tour when authenticated as tour author' do
      user = create(:user, super: false)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      user.tours << tour
      signed_cookie(user)
      clean_reindex
      get :show, params: { tenant: tour_set.subdir, id: tour.id }
      expect(response.status).to(eq(200))
      expect(v4_json[:id]).to(eq(tour.id))
    end

    it 'returns 401 when authenticated as site owner but requesting tour for different site' do
      other_tour_set = create(:tour_set)
      user = create(:user, super: false)
      Apartment::Tenant.switch!(other_tour_set.subdir)
      tour = create(:tour, published: false)
      user.tour_sets << tour_set
      signed_cookie(user)
      clean_reindex
      get :show, params: { tenant: other_tour_set.subdir, id: tour.id }
      expect(response.status).to(eq(401))
    end
  end
end
