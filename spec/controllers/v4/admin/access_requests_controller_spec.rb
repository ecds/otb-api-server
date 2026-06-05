# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(V4::Admin::AccessRequestsController, type: :controller) do
  include ActiveJob::TestHelper

  describe 'GET #index' do
    it 'returns 401 when unauthenticated' do
      tour_set = create(:tour_set)
      get :index, params: { tenant: tour_set.subdir }
      expect(response.status).to(eq(401))
    end

    it 'returns 401 when authenticated if not current tenant admin' do
      user = create(:user, super: false)
      signed_cookie(user)
      tour_set = create(:tour_set)
      get :index, params: { tenant: tour_set.subdir }
      expect(response.status).to(eq(401))
    end

    it 'returns 200 and list of requests when authenticated as current tenant admin' do
      user = create(:user, super: false)
      signed_cookie(user)
      tour_set = create(:tour_set)
      user.tour_sets << tour_set
      create_list(:access_request, 4, tour_set:)
      Apartment::Tenant.switch!(tour_set.subdir)
      get :index, params: { tenant: tour_set.subdir }
      expect(response.status).to(eq(200))
      expect(AccessRequest.count).to(eq(4))
      expect(v4_json.count).to(eq(AccessRequest.count))
    end

    it 'returns 200 and list of requests when authenticated as super' do
      user = create(:user, super: true)
      signed_cookie(user)
      tour_set = create(:tour_set)
      create_list(:access_request, 4, tour_set:)
      Apartment::Tenant.switch!(tour_set.subdir)
      get :index, params: { tenant: tour_set.subdir }
      expect(response.status).to(eq(200))
      expect(AccessRequest.count).to(eq(4))
      expect(v4_json.count).to(eq(AccessRequest.count))
    end

    it 'returns 401 when bad credentials' do
      tour_set = create(:tour_set)
      invalid_signed_cooke
      get :index, params: { tenant: tour_set.subdir }
      expect(response.status).to(eq(401))
    end

    it 'returns 401 when bad credentials and me parameter is present' do
      tour_set = create(:tour_set)
      invalid_signed_cooke
      get :index, params: { tenant: tour_set.subdir, me: true }
      expect(response.status).to(eq(401))
    end

    it 'returns empty array when no requests' do
      user = create(:user, super: true)
      signed_cookie(user)
      tour_set = create(:tour_set)
      expect(AccessRequest.where(tour_set:)).to(be_empty)
      get :index, params: { tenant: tour_set.subdir }
      expect(v4_json).to(be_empty)
    end
  end

  describe 'POST #create' do
    it 'returns 401 when unauthenticated' do
      tour_set = create(:tour_set)
      post :create, params: { tenant: tour_set.subdir, user: create(:user).id }
      expect(response.status).to(eq(401))
    end

    it 'creates new access request' do
      user = create(:user, super: false, tour_sets: [])
      signed_cookie(user)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch!(tour_set.subdir)
      expect do
        post(:create, params: { tenant: tour_set.subdir, user: user.id })
      end.to(change { AccessRequest.count }.by(1))
    end

    it 'creates new access request for tours' do
      tour_set = create(:tour_set)
      Apartment::Tenant.switch!(tour_set.subdir)
      tours = create_list(:tour, 2)
      user = create(:user, super: false, tour_sets: [])
      signed_cookie(user)
      post :create, params: { tenant: tour_set.subdir, user: user.id, tour_ids: [tours.first.id, tours.last.id] }
      expect(v4_json[:tour_ids]).to(include(tours.first.id))
      expect(v4_json[:tour_ids]).to(include(tours.last.id))
    end

    it 'sends an email when access request is created' do
      user = create(:user, super: false, tour_sets: [])
      signed_cookie(user)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch!(tour_set.subdir)
      expect do
        post(:create, params: { tenant: tour_set.subdir, user: user.id })
      end.to(have_enqueued_mail(AccessRequestMailer, :access_request_email))
    end

    it 'sends an email when access request to tour is created' do
      user = create(:user, super: false, tour_sets: [])
      signed_cookie(user)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      expect do
        post(:create, params: { tenant: tour_set.subdir, user: user.id, tour_ids: [tour.id] })
      end.to(have_enqueued_mail(AccessRequestMailer, :access_request_tour_email))
    end
  end

  describe 'PUT #update' do
    it 'returns 401 when unauthenticated' do
      tour_set = create(:tour_set)
      access_request = create(:access_request, tour_set:)
      put :update, params: { tenant: tour_set.subdir, id: access_request.id }
      expect(response).to(have_http_status(:unauthorized))
    end

    it 'approves request to join site' do
      tour_set = create(:tour_set)
      requester = create(:user, super: false, tour_sets: [])
      access_request = create(:access_request, tour_set:, user: requester)
      expect(requester.tour_sets).to(be_empty)
      admin = create(:user, super: false, tour_sets: [tour_set])
      signed_cookie(admin)
      put :update, params: { tenant: tour_set.subdir, id: access_request.id, access_request: { approved: true } }
      expect(response).to(have_http_status(:ok))
      requester.reload
      expect(requester.tour_sets).to(include(tour_set))
    end

    it 'denies request to join site' do
      tour_set = create(:tour_set)
      access_request = create(:access_request, tour_set:)
      expect(access_request.user.tour_sets).to(be_empty)
      admin = create(:user, super: false, tour_sets: [tour_set])
      signed_cookie(admin)
      put :update, params: { tenant: tour_set.subdir, id: access_request.id, access_request: { approved: false } }
      expect(response).to(have_http_status(:ok))
      expect(access_request.user.tour_sets).to(be_empty)
    end

    it 'approves request to join tour' do
      tour_set = create(:tour_set)
      Apartment::Tenant.switch!(tour_set.subdir)
      tours = create_list(:tour, 2)
      access_request = create(:access_request, tour_set:, tour_ids: [tours.first.id, tours.last.id])
      expect(access_request.user.tour_sets).to(be_empty)
      expect(access_request.user.tours).to(be_empty)
      admin = create(:user, super: false, tour_sets: [tour_set])
      signed_cookie(admin)
      put :update, params: { tenant: tour_set.subdir, id: access_request.id, access_request: { approved: true } }
      expect(response).to(have_http_status(:ok))
      expect(access_request.user.tour_sets).to(be_empty)
      expect(access_request.user.tours).to(include(tours.first))
      expect(access_request.user.tours).to(include(tours.last))
    end

    it 'denies request to join tour' do
      tour_set = create(:tour_set)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      access_request = create(:access_request, tour_set:, tour_ids: [tour.id])
      expect(access_request.user.tour_sets).to(be_empty)
      expect(access_request.user.tours).to(be_empty)
      admin = create(:user, super: false, tour_sets: [tour_set])
      signed_cookie(admin)
      put :update, params: { tenant: tour_set.subdir, id: access_request.id, access_request: { approved: false } }
      expect(response).to(have_http_status(:ok))
      expect(access_request.user.tour_sets).to(be_empty)
      expect(access_request.user.tours).to(be_empty)
    end

    it 'approves request but limits to specific tour when request was for whole site' do
      tour_set = create(:tour_set)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      requester = create(:user, super: false)
      admin = create(:user, super: false, tour_sets: [tour_set])
      signed_cookie(admin)
      access_request = create(:access_request, tour_set:, user: requester)
      put :update,
        params: {
          tenant: tour_set.subdir,
          id: access_request.id,
          access_request: { tour_ids: [tour.id.to_s], approved: true },
        }
      Apartment::Tenant.switch!(tour_set.subdir)
      requester.reload
      expect(requester.tours).to(include(tour))
    end
  end

  describe 'DELETE #destroy' do
    it 'allows requester to delete request' do
      tour_set = create(:tour_set)
      user = create(:user, super: false)
      signed_cookie(user)
      access_request = create(:access_request, tour_set:, user:)
      expect do
        delete(:destroy, params: { tenant: tour_set.subdir, id: access_request.id })
      end.to(change(AccessRequest, :count).by(-1))
    end

    it 'disallows non-requester to delete request' do
      tour_set = create(:tour_set)
      user = create(:user, super: false)
      access_request = create(:access_request, tour_set:, user:)
      other_user = create(:user)
      signed_cookie(other_user)
      expect do
        delete(:destroy, params: { tenant: tour_set.subdir, id: access_request.id })
      end.not_to(change(AccessRequest, :count))
    end
  end
end
