require "rails_helper"

RSpec.describe V4::Admin::UsersController, type: :controller do
  describe "GET #index" do
    it "returns 401 when unauthenticated" do
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(response.status).to eq(401)
    end

    it "returns 401 when authenticated but not current tenant admin" do
      user = create(:user, super: false)
      signed_cookie(user)
      tour_set = create(:tour_set)
      get :index, params: { tenant: tour_set.subdir }
      expect(response.status).to eq(401)
    end

    it "returns 200 and list of users when authenticated as current tenant admin" do
      user = create(:user, super: false)
      signed_cookie(user)
      tour_set = create(:tour_set)
      user.tour_sets << tour_set
      Apartment::Tenant.switch! tour_set.subdir
      get :index, params: { tenant: tour_set.subdir }
      expect(response.status).to eq(200)
      expect(v4_json.count).to eq(User.count)
    end

    it "returns 200 and list of users when authenticated as super" do
      user = create(:user, super: true)
      signed_cookie(user)
      tour_set = create(:tour_set)
      get :index, params: { tenant: tour_set.subdir }
      expect(response.status).to eq(200)
      expect(v4_json.count).to eq(User.count)
    end

    it "returns 200 and current user when authenticated and me parameter is present" do
      user = create(:user, super: false)
      signed_cookie(user)
      tour_set = create(:tour_set)
      get :index, params: { tenant: tour_set.subdir, me: true }
      expect(response.status).to eq(200)
      expect(v4_json).to eq(user.search_data)
    end

    it "returns 401 when unauthenticated and me parameter is present" do
      tour_set = create(:tour_set)
      get :index, params: { tenant: tour_set.subdir, me: true }
      expect(response.status).to eq(401)
    end

    it "returns 401 when bad credentials" do
      tour_set = create(:tour_set)
      invalid_signed_cooke
      get :index, params: { tenant: tour_set.subdir }
      expect(response.status).to eq(401)
    end

    it "returns 401 when bad credentials and me parameter is present" do
      tour_set = create(:tour_set)
      invalid_signed_cooke
      get :index, params: { tenant: tour_set.subdir, me: true }
      expect(response.status).to eq(401)
    end
  end
end
