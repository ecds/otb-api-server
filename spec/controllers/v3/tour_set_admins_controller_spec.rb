# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V3::TourSetAdminsController, type: :controller do
  before(:each) {
    create_list(:tour_set, rand(2..5))
    TourSet.all.each { |tour_set| tour_set.update(admins: create_list(:user, rand(2..5))) }
  }

  describe 'GET #index' do
    context 'unauthenticated and unauthorized' do
      it 'returns 401 when not unauthenticated' do
        get :index, params: { tenant: TourSet.first.subdir }
        expect(response.status).to eq(401)
      end

      it 'returns 401 when not unauthenticated but unauthorized' do
        initial_tour_set = TourSet.first
        user = create(:user, super: false)
        user.tour_sets << create(:tour_set)
        expect(user.tour_sets).not_to include initial_tour_set
        signed_cookie(user)
        Apartment::Tenant.switch! initial_tour_set.subdir
        get :index, params: { tenant: initial_tour_set.subdir }
        expect(response.status).to eq(401)
      end
    end

    context 'authorized' do
      it 'responds with 200 and a list of TourSetAdmins when requested by tenant admin' do
        user = create(:user, super: false)
        user.tour_sets << TourSet.last
        signed_cookie(user)
        Apartment::Tenant.switch! TourSet.last.subdir
        get :index, params: { tenant: TourSet.last.subdir }
        expect(response.status).to eq(200)
        expect(json.first[:type]).to eq('tour_set_admins')
        expect(json.count).to eq(TourSetAdmin.count)
      end

      it 'responds with 200 and a list of TourSetAdmins when requested by super' do
        user = create(:user, super: true)
        signed_cookie(user)
        Apartment::Tenant.switch! TourSet.first.subdir
        get :index, params: { tenant: TourSet.first.subdir }
        expect(response.status).to eq(200)
        expect(json.first[:type]).to eq('tour_set_admins')
        expect(json.count).to eq(TourSetAdmin.count)
      end
    end
  end

  describe 'GET #show' do
    it 'returns 405' do
      get :show, params: { tenant: Apartment::Tenant.current, id: TourSetAdmin.first.id }
      expect(response.status).to eq(405)
    end
  end

  describe 'POST #create' do
    it 'returns 405' do
      post :create, params: { tenant: Apartment::Tenant.current, id: TourSetAdmin.first.id }
      expect(response.status).to eq(405)
    end
  end

  describe 'PUT #update' do
    it 'returns 405' do
      put :update, params: { tenant: Apartment::Tenant.current, id: TourSetAdmin.first.id }
      expect(response.status).to eq(405)
    end
  end

  describe 'DELETE #destroy' do
    it 'returns 405' do
      delete :destroy, params: { tenant: Apartment::Tenant.current, id: TourSetAdmin.first.id }
      expect(response.status).to eq(405)
    end
  end
end
