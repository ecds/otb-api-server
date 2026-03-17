require "rails_helper"

RSpec.describe V4::Admin::ToursController, type: :controller do
  before(:each) do
    TourSet.all.each do |ts|
      Apartment::Tenant.switch! ts.subdir
      Tour.reindex
    end
  end

  describe "GET #index" do
    it "return 401 when unauthenticated" do
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(response.status).to eq(401)
    end

    it "returns all all when super user" do
      user = create(:user, super: true)
      signed_cookie(user)
      create_list(:tour, 4)
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(v4_json.count).to eq(Tour.count)
    end

    it "returns all tours when tour set admin" do
      Apartment::Tenant.switch! TourSet.last.subdir
      user = create(:user, super: false)
      signed_cookie(user)
      create_list(:tour, 4)
      user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(v4_json.count).to eq(Tour.count)
    end

    it "returns only tours assigned to user" do
      Apartment::Tenant.switch! TourSet.last.subdir
      user = create(:user, super: false)
      signed_cookie(user)
      create_list(:tour, 4)
      user.tours << [ Tour.first, Tour.last ]
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(v4_json.count).to eq(2)
      expect(v4_json.count).not_to eq(Tour.count)
    end

    it "returns empty list when no tours" do
      user = create(:user, super: true)
      signed_cookie(user)
      Apartment::Tenant.switch! TourSet.second.subdir
      Stop.all.each(&:destroy)
      Tour.all.each(&:destroy)
      expect(Tour.count).to be_zero
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(v4_json.count).to be_zero
    end
  end

  describe "GET #show" do
    it "returns 401 when unauthenticated" do
      tour = create(:tour)
      get :show, params: { tenant: Apartment::Tenant.current, id: tour.id }
      expect(response.status).to eq(401)
    end

    it "returns 200 and list of stops when authenticated as super" do
      user = create(:user, super: true)
      signed_cookie(user)
      create_list(:tour, 4)
      Tour.reindex
      get :show, params: { tenant: Apartment::Tenant.current, id: Tour.first.id }
      expect(response.status).to eq(200)
      expect(v4_json[:title]).to eq(Tour.first.title)
    end

    it "returns 200 a tour when authenticated as site owner" do
      user = create(:user, super: false)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch! tour_set.subdir
      tour = create(:tour)
      user.tour_sets << tour_set
      signed_cookie(user)
      Tour.reindex
      get :show, params: { tenant: tour_set.subdir, id: tour.id }
      expect(response.status).to eq(200)
      expect(v4_json[:title]).to eq(tour.title)
    end

    it "returns 200 a tour when authenticated as tour author" do
      user = create(:user, super: false)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch! tour_set.subdir
      tour = create(:tour)
      user.tours << tour
      signed_cookie(user)
      Tour.reindex
      get :show, params: { tenant: tour_set.subdir, id: tour.id }
      expect(response.status).to eq(200)
      expect(v4_json[:id]).to eq(tour.id)
    end

    it "returns 401 when authenticated as site owner but requesting tour for different site" do
      user = create(:user, super: false)
      tour_sets = create_list(:tour_set, 4)
      Apartment::Tenant.switch! tour_sets.first.subdir
      tour = create(:tour, published: false)
      user.tour_sets << tour_sets.last
      signed_cookie(user)
      Tour.reindex
      get :show, params: { tenant: tour_sets.first.subdir, id: tour.id }
      expect(response.status).to eq(401)
    end
  end
end
