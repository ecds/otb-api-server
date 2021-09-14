# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V3::MapIconsController, type: :controller do
  describe 'GET #index' do
    it 'returns all map icons' do
      create_list(:map_icon, rand(2..6))
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(json.count).to eq(MapIcon.count)
    end
  end

  describe 'GET #show' do
    context 'unauthenticated and unauthorized' do
      it 'returns empty MapIcon when not unauthenticated' do
        tour = create(:tour, published: false, stops: create_list(:stop, 3))
        map_icon = create(:map_icon, stop: tour.stops.last)
        get :show, params: { tenant: TourSet.first.subdir, id: map_icon.id }
        expect(response.status).to eq(200)
        expect(json[:id]).to eq(map_icon.id.to_s)
      end

      it 'returns empty MapIcon when not unauthenticated but unauthorized' do
        initial_tenant = Apartment::Tenant.current
        tour = create(:tour, published: false, stops: create_list(:stop, 3))
        map_icon = create(:map_icon, stop: tour.stops.last)
        user = create(:user, super: false)
        user.tour_sets << create(:tour_set)
        expect(user.tour_sets).not_to include TourSet.find_by(subdir: initial_tenant)
        signed_cookie(user)
        Apartment::Tenant.switch! initial_tenant
        get :show, params: { tenant: initial_tenant, id: map_icon }
        expect(response.status).to eq(200)
        expect(json[:id]).to eq(map_icon.id.to_s)
      end
    end

    context 'authorized' do
      it 'responds with 200 and a MapIcon when tour is published' do
        tour = create(:tour, published: true, stops: create_list(:stop, 3))
        map_icon = create(:map_icon, stop: tour.stops.last)
        get :show, params: { tenant: TourSet.first.subdir, id: map_icon.id }
        expect(response.status).to eq(200)
        expect(json[:id]).to eq(map_icon.id.to_s)
      end

      it 'responds with 200 and a MapIcon when requested by a tour author' do
        tour = create(:tour, published: false, stops: create_list(:stop, 3))
        map_icon = create(:map_icon, stop: tour.stops.last)
        user = create(:user, super: false)
        user.tours << tour
        signed_cookie(user)
        get :show, params: { tenant: Apartment::Tenant.current, id: map_icon }
        expect(response.status).to eq(200)
        expect(json[:id]).to eq(map_icon.id.to_s)
      end

      it 'responds with 200 and a list of MapIcon when requested by tenant admin' do
        tour = create(:tour, published: false, stops: create_list(:stop, 3))
        map_icon = create(:map_icon, stop: tour.stops.last)
        user = create(:user, super: false)
        user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
        signed_cookie(user)
        get :show, params: { tenant: Apartment::Tenant.current, id: map_icon }
        expect(response.status).to eq(200)
        expect(json[:id]).to eq(map_icon.id.to_s)
      end

      it 'responds with 200 and a MapIcon when requested by super' do
        tour = create(:tour, published: false, stops: create_list(:stop, 3))
        map_icon = create(:map_icon, stop: tour.stops.last)
        user = create(:user, super: true)
        signed_cookie(user)
        get :show, params: { tenant: Apartment::Tenant.current, id: map_icon }
        expect(response.status).to eq(200)
        expect(json[:id]).to eq(map_icon.id.to_s)
      end
    end
  end

  describe 'POST #create' do
    let(:tour) { create(:tour, stops: create_list(:stop, 2)) }
    let(:valid_params) {
      {
        data: {
          type: 'map_icon',
          attributes: {
            filename: Faker::File.file_name(dir: '', ext: 'png', directory_separator: ''),
            base_sixty_four: File.read(Rails.root.join('spec/factories/images/icon_base64.txt')),
            tour_id: tour.id
          }
        },
        tenant: Apartment::Tenant.current
      }
    }

    context 'unauthorized' do
      it 'returns 401 when unauthenticated' do
        initial_map_icon_count = MapIcon.count
        post :create, params: valid_params
        expect(response.status).to eq(401)
        expect(MapIcon.count).to eq(initial_map_icon_count)
      end

      it 'returns 401 when authenticated but unauthorized tenant admin' do
        initial_map_icon_count = MapIcon.count
        initial_tenant = Apartment::Tenant.current
        user = create(:user, super: false)
        user.tour_sets << create(:tour_set)
        expect(user.tour_sets).not_to include TourSet.find_by(subdir: initial_tenant)
        signed_cookie(user)
        Apartment::Tenant.switch! initial_tenant
        valid_params[:tenant] = initial_tenant
        post :create, params: valid_params
        expect(response.status).to eq(401)
        expect(MapIcon.count).to eq(initial_map_icon_count)
      end
    end

    context 'authorized' do
      it 'creates when request by super' do
        user = create(:user, super: true)
        signed_cookie(user)
        expect {
          post :create, params: valid_params
        }.to change(MapIcon, :count).by(1)
      end

      it 'creates when request by current tenant admin' do
        user = create(:user, super: false)
        user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
        signed_cookie(user)
        expect {
          post :create, params: valid_params
        }.to change(MapIcon, :count).by(1)
      end

      it 'creates when request by tour author' do
        user = create(:user, super: false)
        user.tours << tour
        signed_cookie(user)
        expect {
          post :create, params: valid_params
        }.to change(MapIcon, :count).by(1)
      end
    end

    context 'invalid params' do
      let(:tour) { create(:tour, stops: create_list(:stop, 2)) }
      let(:invalid_params) {
        {
          data: {
            type: 'map_icon',
            attributes: {
              filename: Faker::File.file_name(dir: '', ext: 'png', directory_separator: ''),
              base_sixty_four: File.read(Rails.root.join('spec/factories/images/atl_base64.txt')),
              tour_id: tour.id
            }
          },
          tenant: Apartment::Tenant.current
        }
      }

      it 'returns 422 with invalid params' do
        initial_map_icon_count = MapIcon.count
        user = create(:user, super: true)
        signed_cookie(user)
        post :create, params: { tenant: Apartment::Tenant.current, data: {} }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(MapIcon.count).to eq(initial_map_icon_count)
      end

      it 'returns 422 and size error message' do
        initial_map_icon_count = MapIcon.count
        user = create(:user, super: true)
        signed_cookie(user)
        post :create, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(MapIcon.count).to eq(initial_map_icon_count)
        expect(errors).to include('Icons should be no bigger that 80 by 80 pixels')
      end
    end
  end
end
