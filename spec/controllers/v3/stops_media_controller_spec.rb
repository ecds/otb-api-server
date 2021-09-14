require 'rails_helper'

RSpec.describe V3::StopMediaController, type: :controller do

  describe 'GET #index' do
    before(:each) { Tour.all.each { |tour| tour.update(published: false) } }

    context 'unauthenticated' do
      it 'returns a success response but zero StopMedium objects' do
        create(:stop_medium, stop: create(:stop))
        get :index, params: { tenant: Apartment::Tenant.current }
        expect(response.status).to eq(200)
        expect(json.count).to eq(0)
        expect(StopMedium.count).to be > 0
      end
    end

    context 'authenticated unauthorized' do
      it 'returns zero StopMedium objects, not current tenant admin, non tour author' do
        original_tenant = Apartment::Tenant.current
        stop_medium = create(:stop_medium, stop: create(:stop))
        tour_set = create(:tour_set)
        user = create(:user, super: false)
        user.tour_sets << tour_set
        signed_cookie(user)
        get :index, params: { tenant: original_tenant }
        Apartment::Tenant.switch! original_tenant
        expect(response.status).to eq(200)
        expect(json.count).to eq(0)
        expect(StopMedium.count).to be > 0
      end

      it 'returns zero StopMedium objects, not current tenant admin, non tour author' do
        original_tenant = Apartment::Tenant.current
        stop_medium = create(:stop_medium, stop: create(:stop))
        tour_set = create(:tour_set)
        Apartment::Tenant.switch! tour_set.subdir
        user = create(:user, super: false)
        user.tours << create(:tour)
        signed_cookie(user)
        Apartment::Tenant.switch! original_tenant
        get :index, params: { tenant: original_tenant }
        expect(response.status).to eq(200)
        expect(json.count).to eq(0)
        expect(StopMedium.count).to be > 0
      end
    end

    context 'authenticated and authorized' do
      it 'returns all StopMedium objects to super' do
        create_list(:stop_medium, 4)
        user = create(:user, super: true)
        signed_cookie(user)
        get :index, params: { tenant: Apartment::Tenant.current }
        expect(response.status).to eq(200)
        expect(json.count).to eq(StopMedium.count)
      end

      it 'returns all StopMedium objects to tenant admin' do
        create_list(:stop_medium, 4)
        user = create(:user, super: false)
        user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
        signed_cookie(user)
        get :index, params: { tenant: Apartment::Tenant.current }
        expect(response.status).to eq(200)
        expect(json.count).to eq(StopMedium.count)
      end
    end
  end

  describe 'GET #show' do
    context 'unauthenticated' do
      it 'returns a success response but empty StopMedium objects' do

        stop_medium = create(:stop_medium, stop: create(:stop))
        get :show, params: { id: stop_medium.id, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(200)
        expect(relationships[:medium][:data]).to be nil
        expect(relationships[:stop][:data]).to be nil
        expect(stop_medium.stop).not_to be nil
        expect(stop_medium.medium).not_to be nil
        expect(StopMedium.count).to be > 0
      end

      # it 'returns a success response but empty StopMedium objects' do
      #   stop_medium = create(:stop_medium, stop: create(:stop))
      #   get :index, params: { id: stop_medium.id, tenant: Apartment::Tenant.current }
      #   expect(response.status).to eq(200)
      #   expect(json.count).to eq(1)
      # end
    end

    context 'authenticated unauthorized' do

      it 'returns empty StopMedium objects, not current tenant admin, non tour author' do
        original_tenant = Apartment::Tenant.current
        stop_medium = create(:stop_medium, stop: create(:stop))
        tour_set = create(:tour_set)
        user = create(:user, super: false)
        user.tour_sets << tour_set
        signed_cookie(user)
        Apartment::Tenant.switch! original_tenant
        get :show, params: { id: stop_medium.id, tenant: original_tenant }
        expect(response.status).to eq(200)
        expect(relationships[:medium][:data]).to be nil
        expect(relationships[:stop][:data]).to be nil
        expect(stop_medium.stop).not_to be nil
        expect(stop_medium.medium).not_to be nil
        expect(StopMedium.count).to be > 0
      end

      it 'returns empty StopMedium objects, not current tenant admin, non tour author' do
        original_tenant = Apartment::Tenant.current
        stop_medium = create(:stop_medium, stop: create(:stop))
        tour_set = create(:tour_set)
        Apartment::Tenant.switch! tour_set.subdir
        user = create(:user, super: false)
        user.tours << create(:tour)
        signed_cookie(user)
        Apartment::Tenant.switch! original_tenant
        get :show, params: { id: stop_medium.id, tenant: original_tenant }
        expect(response.status).to eq(200)
        expect(relationships[:medium][:data]).to be nil
        expect(relationships[:stop][:data]).to be nil
        expect(StopMedium.count).to be > 0
      end
    end

    context 'authenticated and authorized' do
      it 'returns all StopMedium objects to super' do
        create_list(:stop_medium, 4)
        user = create(:user, super: true)
        signed_cookie(user)
        get :show, params: { id: StopMedium.last.id, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(200)
        expect(json.count).to eq(StopMedium.count)
      end
    end
  end

  describe 'POST #create' do
    it 'returns does not create a new StopMedium' do
      expect {
        post :create, params: { tenant: Apartment::Tenant.current }
      }.to change(StopMedium, :count).by(0)
    end

    it 'returns 401' do
      user = create(:user, super: true)
      signed_cookie(user)
      post :create, params: { data: { type: 'stop_media', attributes: { stop_id: 1, medium_id: 1, position: 1 } }, tenant: Apartment::Tenant.current }
      expect(response.status).to eq(401)
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      it 'renders a JSON response with the v3_stop_medium' do
        stop_medium = create(:stop_medium, position: 1)
        expect(stop_medium.position).not_to eq(100)
        user = create(:user, super: true)
        signed_cookie(user)
        put :update, params: { id: stop_medium.id, data: { type: 'stop_media', attributes: { stop_id: stop_medium.stop.id, medium_id: stop_medium.medium.id, position: 100 } }, tenant: Apartment::Tenant.current }
        expect(response).to have_http_status(:ok)
        expect(attributes[:position]).to eq(100)
        expect(StopMedium.find(stop_medium.id).position).to eq(100)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'does not destroy the requested v3_stop_medium' do
      stop_medium = create(:stop_medium)
      user = create(:user, super: true)
      signed_cookie(user)
      expect {
        delete :destroy, params: { id: stop_medium.to_param, tenant: Apartment::Tenant.current }
      }.to change(StopMedium, :count).by(0)
    end

    it 'responds with 405' do
      stop_medium = create(:stop_medium)
      user = create(:user, super: true)
      signed_cookie(user)
      delete :destroy, params: { id: stop_medium.to_param, tenant: Apartment::Tenant.current }
      expect(response.status).to eq(405)
    end
  end
end
