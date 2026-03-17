require "rails_helper"

RSpec.describe V4::Admin::MediaController, type: :controller do
  describe "GET #index" do
    it "returns 401 when unauthenticated" do
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(response.status).to eq(401)
    end

    it "returns 200 and list of medium when authenticated as super" do
      user = create(:user, super: true)
      signed_cookie(user)
      create_list(:medium, 4)
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(response.status).to eq(200)
      expect(v4_json.count).to eq(Medium.count)
    end

    it "returns 200 and list of medium when authenticated as site owner" do
      user = create(:user, super: false)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch! tour_set.subdir
      create_list(:medium, 3)
      user.tour_sets << tour_set
      signed_cookie(user)
      get :index, params: { tenant: tour_set.subdir }
      expect(response.status).to eq(200)
      expect(v4_json.count).to eq(Medium.count)
    end

    it "returns 200 and list of medium when authenticated as tour author" do
      user = create(:user, super: false)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch! tour_set.subdir
      tour = create(:tour)
      create_list(:medium, 2)
      user.tours << tour
      signed_cookie(user)
      get :index, params: { tenant: tour_set.subdir }
      expect(response.status).to eq(200)
      expect(v4_json.count).to eq(Medium.count)
    end

    it "returns 401 when authenticated as site owner but requesting medium for different site" do
      user = create(:user, super: false)
      tour_sets = create_list(:tour_set, 4)
      Apartment::Tenant.switch! tour_sets.first.subdir
      user.tour_sets << tour_sets.last
      signed_cookie(user)
      get :index, params: { tenant: tour_sets.first.subdir }
      expect(response.status).to eq(401)
    end

    it "returns 200 and paginated list of medium when authenticated as site owner" do
      user = create(:user, super: false)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch! tour_set.subdir
      create_list(:medium, 3)
      user.tour_sets << tour_set
      signed_cookie(user)
      get :index, params: { tenant: tour_set.subdir, page: 2, per: 1 }
      expect(response.status).to eq(200)
      expect(v4_json.count).to eq(1)
    end

    it "returns 200 with specified media excluded" do
      user = create(:user, super: true)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch! tour_set.subdir
      media = create_list(:medium, 4)
      user.tour_sets << tour_set
      signed_cookie(user)
      get :index, params: { tenant: tour_set.subdir, exclude: "#{media.first.id}, #{media.second.id}" }
      expect(response.status).to eq(200)
      expect(v4_json.count).to eq(Medium.count - 2)
      expect(v4_json.map { |m| m[:id] }).not_to include(media.first.id)
      expect(v4_json.map { |m| m[:id] }).not_to include(media.second.id)
    end
  end
end
