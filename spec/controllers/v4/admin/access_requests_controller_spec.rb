require "rails_helper"

RSpec.describe V4::Admin::AccessRequestsController, type: :controller do
  include ActiveJob::TestHelper

  describe "GET #index" do
    it "returns 401 when unauthenticated" do
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(response.status).to eq(401)
    end

    it "returns 401 when authenticated if not current tenant admin" do
      user = create(:user, super: false)
      signed_cookie(user)
      tour_set = create(:tour_set)
      get :index, params: { tenant: tour_set.subdir }
      expect(response.status).to eq(401)
    end

    it "returns 200 and list of requests when authenticated as current tenant admin" do
      user = create(:user, super: false)
      signed_cookie(user)
      tour_set = create(:tour_set)
      user.tour_sets << tour_set
      create_list(:access_request, 4, tour_set: tour_set.subdir)
      Apartment::Tenant.switch! tour_set.subdir
      get :index, params: { tenant: tour_set.subdir }
      expect(response.status).to eq(200)
      expect(AccessRequest.count).to eq(4)
      expect(v4_json.count).to eq(AccessRequest.count)
    end

    it "returns 200 and list of users when authenticated as super" do
      user = create(:user, super: true)
      signed_cookie(user)
      tour_set = create(:tour_set)
      create_list(:access_request, 4, tour_set: tour_set.subdir)
      Apartment::Tenant.switch! tour_set.subdir
      get :index, params: { tenant: tour_set.subdir }
      expect(response.status).to eq(200)
      expect(AccessRequest.count).to eq(4)
      expect(v4_json.count).to eq(AccessRequest.count)
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

  describe "POST #create" do
    it "returns 401 when unauthenticated" do
      get :create, params: { tenant: Apartment::Tenant.current, user: User.first.id }
      expect(response.status).to eq(401)
    end

    it "creates new access request" do
      user = create(:user, super: false, tour_sets: [])
      signed_cookie(user)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch! tour_set.subdir
      expect {
        post :create, params: { tenant: tour_set.subdir, user: user.id }
      }.to change { AccessRequest.count }.by(1)
    end

    it "sends an email when access request is created" do
      user = create(:user, super: false, tour_sets: [])
      signed_cookie(user)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch! tour_set.subdir
      expect {
        post :create, params: { tenant: tour_set.subdir, user: user.id }
      }.to have_enqueued_mail(AccessRequestMailer, :access_request_email)
    end

    it "sends an email when access request to tour is created" do
      user = create(:user, super: false, tour_sets: [])
      signed_cookie(user)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch! tour_set.subdir
      tour = create(:tour)
      expect {
        post :create, params: { tenant: tour_set.subdir, user: user.id, tour: tour.id }
      }.to have_enqueued_mail(AccessRequestMailer, :access_request_tour_email)
    end
  end

  describe "PUT #update" do
    it "returns 401 when unauthenticated" do
      access_request = create(:access_request, tour_set: Apartment::Tenant.current)
      put :update, params: { tenant: Apartment::Tenant.current, id: access_request.id }
      expect(response.status).to eq(401)
    end

    it "approves request to join site" do
      tour_set = TourSet.last
      Apartment::Tenant.switch! tour_set.subdir
      access_request = create(:access_request, tour_set: Apartment::Tenant.current)
      expect(access_request.user.tour_sets).to be_empty
      admin = create(:user, super: false, tour_sets: [ tour_set ])
      signed_cookie(admin)
      put :update, params: { tenant: tour_set.subdir, id: access_request.id, access_request: { approved: true } }
      expect(access_request.user.tour_sets).to include(tour_set)
    end

    it "denies request to join site" do
      tour_set = TourSet.second
      Apartment::Tenant.switch! tour_set.subdir
      access_request = create(:access_request, tour_set: Apartment::Tenant.current)
      expect(access_request.user.tour_sets).to be_empty
      admin = create(:user, super: false, tour_sets: [ tour_set ])
      signed_cookie(admin)
      put :update, params: { tenant: tour_set.subdir, id: access_request.id, access_request: { approved: false } }
      expect(access_request.user.tour_sets).to be_empty
    end

    it "approves request join tour" do
      tour_set = TourSet.last
      Apartment::Tenant.switch! tour_set.subdir
      tour = create(:tour)
      access_request = create(:access_request, tour_set: Apartment::Tenant.current, tour: tour.id)
      expect(access_request.user.tour_sets).to be_empty
      expect(access_request.user.tours).to be_empty
      admin = create(:user, super: false, tour_sets: [ tour_set ])
      signed_cookie(admin)
      put :update, params: { tenant: tour_set.subdir, id: access_request.id, access_request: { approved: true } }
      expect(access_request.user.tour_sets).to be_empty
      expect(access_request.user.tours).to include(tour)
    end

    it "denies request join tour" do
      tour_set = TourSet.first
      Apartment::Tenant.switch! tour_set.subdir
      tour = create(:tour)
      access_request = create(:access_request, tour_set: Apartment::Tenant.current, tour: tour.id)
      expect(access_request.user.tour_sets).to be_empty
      expect(access_request.user.tours).to be_empty
      admin = create(:user, super: false, tour_sets: [ tour_set ])
      signed_cookie(admin)
      put :update, params: { tenant: tour_set.subdir, id: access_request.id, access_request: { approved: false } }
      expect(access_request.user.tour_sets).to be_empty
      expect(access_request.user.tours).to be_empty
    end
  end
end
