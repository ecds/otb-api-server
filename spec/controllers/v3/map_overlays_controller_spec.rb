# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V3::MapOverlaysController, type: :controller do
  describe 'GET #index' do
    context 'unauthenticated and unauthorized' do
      it 'returns empty MapOverlay when not unauthenticated' do
        tour = create(:tour, published: false, stops: create_list(:stop, 3))
        map_overlay = create(:map_overlay, tour: tour)
        get :show, params: { tenant: TourSet.first.subdir, id: map_overlay.id }
        expect(response.status).to eq(200)
        expect(json[:id]).to eq(map_overlay.id.to_s)
        expect(attributes[:south]).not_to eq(map_overlay.south.to_f.to_s)
        expect(attributes[:east]).to be nil
      end

      it 'returns empty MapOverlay when not unauthenticated but unauthorized' do
        initial_tenant = Apartment::Tenant.current
        tour = create(:tour, published: false, stops: create_list(:stop, 3))
        map_overlay = create(:map_overlay, tour: tour)
        user = create(:user, super: false)
        user.tour_sets << create(:tour_set)
        expect(user.tour_sets).not_to include TourSet.find_by(subdir: initial_tenant)
        signed_cookie(user)
        Apartment::Tenant.switch! initial_tenant
        get :show, params: { tenant: initial_tenant, id: map_overlay }
        expect(response.status).to eq(200)
        expect(json[:id]).to eq(map_overlay.id.to_s)
        expect(attributes[:north]).not_to eq(map_overlay.north.to_f.to_s)
        expect(attributes[:west]).to be nil
      end
    end

    context 'authorized' do
      it 'responds with 200 and a MapOverlay when tour is published' do
        tour = create(:tour, published: true, stops: create_list(:stop, 3))
        map_overlay = create(:map_overlay, tour: tour)
        get :show, params: { tenant: TourSet.first.subdir, id: map_overlay.id }
        expect(response.status).to eq(200)
        expect(json[:id]).to eq(map_overlay.id.to_s)
        expect(attributes[:south]).to eq(map_overlay.south.to_f.to_s)
      end

      it 'responds with 200 and a MapOverlay when requested by a tour author' do
        tour = create(:tour, published: false, stops: create_list(:stop, 3))
        map_overlay = create(:map_overlay, tour: tour)
        user = create(:user, super: false)
        user.tours << tour
        signed_cookie(user)
        get :show, params: { tenant: Apartment::Tenant.current, id: map_overlay }
        expect(response.status).to eq(200)
        expect(json[:id]).to eq(map_overlay.id.to_s)
        expect(attributes[:north]).to eq(map_overlay.north.to_f.to_s)
      end

      it 'responds with 200 and a list of MapOverlay when requested by tenant admin' do
        tour = create(:tour, published: false, stops: create_list(:stop, 3))
        map_overlay = create(:map_overlay, tour: tour)
        user = create(:user, super: false)
        user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
        signed_cookie(user)
        get :show, params: { tenant: Apartment::Tenant.current, id: map_overlay }
        expect(response.status).to eq(200)
        expect(json[:id]).to eq(map_overlay.id.to_s)
        expect(attributes[:north]).to eq(map_overlay.north.to_f.to_s)
      end

      it 'responds with 200 and a MapOverlay when requested by super' do
        tour = create(:tour, published: false, stops: create_list(:stop, 3))
        map_overlay = create(:map_overlay, tour: tour)
        user = create(:user, super: true)
        signed_cookie(user)
        get :show, params: { tenant: Apartment::Tenant.current, id: map_overlay }
        expect(response.status).to eq(200)
        expect(json[:id]).to eq(map_overlay.id.to_s)
        expect(attributes[:north]).to eq(map_overlay.north.to_f.to_s)
      end
    end
  end

  describe 'POST #create' do
    let(:tour) { create(:tour, stops: create_list(:stop, 2)) }
    let(:valid_params) {
      {
        data: {
          type: 'map_overlay',
          attributes: {
            filename: Faker::File.file_name(dir: '', ext: 'png', directory_separator: ''),
            base_sixty_four: File.read(Rails.root.join('spec/factories/base64_image.txt')),
            tour_id: tour.id
          }
        },
        tenant: Apartment::Tenant.current
      }
    }

    context 'unauthorized' do
      it 'returns 401 when unauthenticated' do
        initial_map_overlay_count = MapOverlay.count
        post :create, params: valid_params
        expect(response.status).to eq(401)
        expect(MapOverlay.count).to eq(initial_map_overlay_count)
      end

      it 'returns 401 when authenticated but unauthorized tenant admin' do
        initial_map_overlay_count = MapOverlay.count
        initial_tenant = Apartment::Tenant.current
        user = create(:user, super: false)
        user.tour_sets << create(:tour_set)
        expect(user.tour_sets).not_to include TourSet.find_by(subdir: initial_tenant)
        signed_cookie(user)
        Apartment::Tenant.switch! initial_tenant
        valid_params[:tenant] = initial_tenant
        post :create, params: valid_params
        expect(response.status).to eq(401)
        expect(MapOverlay.count).to eq(initial_map_overlay_count)
      end
    end

    context 'authorized' do
      it 'creates when request by super' do
        user = create(:user, super: true)
        signed_cookie(user)
        expect {
          post :create, params: valid_params
        }.to change(MapOverlay, :count).by(1)
      end

      it 'creates when request by current tenant admin' do
        user = create(:user, super: false)
        user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
        signed_cookie(user)
        expect {
          post :create, params: valid_params
        }.to change(MapOverlay, :count).by(1)
      end

      it 'creates when request by tour author' do
        user = create(:user, super: false)
        user.tours << tour
        signed_cookie(user)
        expect {
          post :create, params: valid_params
        }.to change(MapOverlay, :count).by(1)
      end
    end

    context 'invalid params' do
      it 'returns 422 with invalid params' do
        initial_map_overlay_count = MapOverlay.count
        user = create(:user, super: true)
        signed_cookie(user)
        post :create, params: { tenant: Apartment::Tenant.current, data: {} }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(MapOverlay.count).to eq(initial_map_overlay_count)
      end
    end
  end
end
