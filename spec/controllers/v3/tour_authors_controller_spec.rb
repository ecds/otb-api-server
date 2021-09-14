# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V3::TourAuthorsController, type: :controller do
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

      it 'returns 401 when authenticated but unauthorized' do
        initial_tour_set = TourSet.find_by(subdir: Apartment::Tenant.current)
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
      it 'responds with 200 and a list of TourAuthors when requested by tenant admin' do
        create_list(:tour_author, rand(3..4))
        user = create(:user, super: false)
        user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
        signed_cookie(user)
        get :index, params: { tenant: Apartment::Tenant.current }
        expect(response.status).to eq(200)
        expect(json.first[:type]).to eq('tour_authors')
        expect(TourAuthor.count).to be > 1
        expect(json.count).to eq(TourAuthor.count)
      end

      it 'responds with 200 and a list of TourAuthors when requested by super' do
        create_list(:tour_author, rand(4..6))
        user = create(:user, super: true)
        signed_cookie(user)
        get :index, params: { tenant: Apartment::Tenant.current }
        expect(response.status).to eq(200)
        expect(json.first[:type]).to eq('tour_authors')
        expect(TourAuthor.count).to be > 1
        expect(json.count).to eq(TourAuthor.count)
      end
    end
  end

  describe 'GET #show' do
    context 'unauthorized' do
      it 'returns 401 when unauthenticated' do
        tour_author = create(:tour_author)
        get :show, params: { tenant: Apartment::Tenant.current, id: tour_author.id }
        expect(response.status).to eq(401)
      end

      it 'returns 401 when authenticated but not authorized' do
        tour_author = create(:tour_author)
        initial_tour_set = TourSet.find_by(subdir: Apartment::Tenant.current)
        user = create(:user, super: false)
        user.tour_sets << create(:tour_set)
        expect(user.tour_sets).not_to include initial_tour_set
        signed_cookie(user)
        Apartment::Tenant.switch! initial_tour_set.subdir
        get :show, params: { tenant: Apartment::Tenant.current, id: tour_author.id }
        expect(response.status).to eq(401)
      end
    end

    context 'authorized' do
      it 'responds with 200 and a list of TourAuthors when requested by tenant admin' do
        tour_author = create(:tour_author)
        user = create(:user, super: false)
        user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
        signed_cookie(user)
        get :show, params: { tenant: Apartment::Tenant.current, id: tour_author.id }
        expect(response.status).to eq(200)
        expect(json[:type]).to eq('tour_authors')
        expect(json[:id]).to eq(tour_author.id.to_s)
      end

      it 'responds with 200 and a list of TourAuthors when requested by super' do
        tour_author = create(:tour_author)
        user = create(:user, super: true)
        signed_cookie(user)
        get :show, params: { tenant: Apartment::Tenant.current, id: tour_author.id }
        expect(response.status).to eq(200)
        expect(json[:type]).to eq('tour_authors')
        expect(json[:id]).to eq(tour_author.id.to_s)
      end
    end
  end

  describe 'POST #create' do
    it 'returns 405' do
      post :create, params: { tenant: Apartment::Tenant.current, data: {} }
      expect(response.status).to eq(405)
    end
  end

  describe 'PUT #update' do
    it 'returns 405' do
      tour_author = create(:tour_author)
      put :update, params: { tenant: Apartment::Tenant.current, id: tour_author.id }
      expect(response.status).to eq(405)
    end
  end

  describe 'DELETE #destroy' do
    it 'returns 405' do
      tour_author = create(:tour_author)
      delete :destroy, params: { tenant: Apartment::Tenant.current, id: tour_author.id }
      expect(response.status).to eq(405)
    end
  end
end
