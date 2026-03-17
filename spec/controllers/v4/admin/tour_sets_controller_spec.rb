require "rails_helper"

RSpec.describe V4::Admin::TourSetsController, type: :controller do
  before(:each) do
    TourSet.all.each do |ts|
      Apartment::Tenant.switch! ts.subdir
      Tour.reindex
    end
  end

  describe "GET #index" do
    it "return 401 when unauthenticated" do
      get :index, params: { tenant: "public" }
      expect(response.status).to eq(401)
      expect(v4_json[:error]).to eq("unauthorized")
    end

    it "returns all TourSet when authenticated as super" do
      user = create(:user, super: true)
      signed_cookie(user)
      get :index, params: { tenant: "public" }
      expect(response.status).to eq(200)
      expect(v4_json.count).to eq(TourSet.count)
    end

    it "returns only TourSets when assigned to user" do
      # We want any authenticated user to get all the TourSets
      # so they can request access.
      Apartment::Tenant.switch! TourSet.first.subdir
      Tour.all.each { |t| t.update(published: false) }
      Apartment::Tenant.reset
      user = create(:user, super: false)
      user.tour_sets << create_list(:tour_set, 3)
      signed_cookie(user)
      get :index, params: { tenant: "public" }
      expect(response.status).to eq(200)
      expect(v4_json.count).to eq(TourSet.count)
      expect(v4_json.count).to be > user.tour_sets.count
    end
  end

  describe "GET #show" do
    it "returns 401 when unauthenticated" do
      get :show, params: { tenant: "public", slug: Apartment::Tenant.current }
      expect(response.status).to eq(401)
    end

    it "returns 200 and a tour set authenticated as super" do
      user = create(:user, super: true)
      signed_cookie(user)
      get :show, params: { tenant: "public", slug: Apartment::Tenant.current }
      expect(response.status).to eq(200)
    end

    it "returns 200 a tour set when authenticated as site owner" do
      user = create(:user, super: false)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch! tour_set.subdir
      user.tour_sets << tour_set
      signed_cookie(user)
      get :show, params: { tenant: "public", slug: tour_set.subdir }
      expect(response.status).to eq(200)
      expect(v4_json[:name]).to eq(tour_set.name)
    end

    it "returns 401 no tour sets when authenticated as tour author" do
      user = create(:user, super: false)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch! tour_set.subdir
      tour = create(:tour)
      user.tours << tour
      user.update(tour_sets: [])
      signed_cookie(user)
      get :show, params: { tenant: "public", slug: tour_set.subdir }
      expect(response.status).to eq(401)
    end

    it "returns 401 when authenticated as site owner but requesting stops for different site" do
      user = create(:user, super: false)
      tour_sets = create_list(:tour_set, 4)
      Apartment::Tenant.switch! tour_sets.first.subdir
      user.tour_sets << tour_sets.last
      signed_cookie(user)
      Tour.reindex
      get :show, params: { tenant: "public", slug: tour_sets.first.subdir }
      expect(response.status).to eq(401)
    end
  end
end
