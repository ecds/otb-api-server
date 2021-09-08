# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V3::StopsController, type: :controller do
  describe 'GET #index' do
    it 'returns a 200 response with stops connected to published tours' do
      create_list(:tour_with_stops, 5, theme: create(:theme), mode: create(:mode))
      Tour.first.update(published: true)
      Tour.last.update(published: false)
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(response.status).to eq(200)
      expect(Tour.count).to be > Tour.published.count
      json.each do |stop|
        expect(Stop.find(stop[:id]).tours.any? { |tour| tour.published })
      end
      expect(json.count).to be < Stop.count
    end

    it 'returns a 200 response with no stops when request is authenticated by person with no access' do
      create_list(:tour_with_stops, 5, theme: create(:theme), mode: create(:mode))
      Tour.first.update(published: true) if Tour.published.empty?
      Tour.last.update(published: false) if Tour.published.count == Tour.count
      Tour.last.stops.tours = [] if Tour.last.stops.count > 1
      if Stop.all.all? { |s| s.published }
        Stop.last.update(tours: [])
      end
      user = create(:user)
      user.tour_sets = []
      user.tours = []
      signed_cookie(user)
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(response.status).to eq(200)
      expect(Tour.count).to be > Tour.published.count
      json.each do |stop|
        expect(Stop.find(stop[:id]).tours.any? { |tour| tour.published })
      end
      expect(json.count).to be < Stop.count
    end

    it 'returns a 200 response with stops when request is authenticated by tenant admin and tour is unpublished' do
      tour = create(:tour, published: false)
      tour.update(published: false)
      user = create(:user)
      user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
      signed_cookie(user)
      get :index, params: { tenant: tour.tenant }
      expect(Stop.count).to be > 1
      expect(response.status).to eq(200)
      expect(json.count).to eq(Stop.count)
    end

    it 'returns a 200 response when request is authenticated by tour author and tour is unpublished' do
      create_list(:tour_with_stops, 5, theme: create(:theme), mode: create(:mode))
      user = create(:user)
      user.tour_sets = []
      user.tours << Tour.first
      signed_cookie(user)
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(response.status).to eq(200)
      expect(json.count).to eq(Tour.first.stops.count)
      expect(json.count).to be < Stop.count
    end
  end

  describe 'GET #show' do
    it 'returns a 200 response that is empty stop' do
      tour = create(:tour)
      tour.update(published: false)
      Stop.all.each { |stop| tour.stops << stop }
      # Make sure the stop is only associated with the newly created tour
      tour.stops.last.update(tours: [tour])
      get :show, params: { tenant: Apartment::Tenant.current, id: tour.stops.last.id }
      expect(response.status).to eq(200)
      expect(json[:id]).to eq(tour.stops.last.id.to_s)
      expect(attributes[:title]).to be_nil
    end

    it 'returns a 200 response and stop when stop is part of published tour' do
      tour = create(:tour)
      tour.update(published: true)
      Stop.all.each { |stop| tour.stops << stop }
      tour.stops.last.update(tours: [tour])
      get :show, params: { tenant: Apartment::Tenant.current, id: tour.stops.last.id }
      expect(response.status).to eq(200)
      expect(attributes[:title]).to eq(tour.stops.last.title)
    end

    it 'returns a 200 response that is empty stop when request is authenticated by someone w/o permission' do
      tour = create(:tour)
      tour.update(published: false)
      Stop.all.each { |stop| tour.stops << stop }
      tour.stops.last.update(tours: [tour])
      user = create(:user)
      user.update(super: false)
      user.tours = []
      user.tour_sets = []
      signed_cookie(user)
      get :show, params: { tenant: Apartment::Tenant.current, id: tour.stops.last.id }
      expect(response.status).to eq(200)
      expect(json[:id]).to eq(tour.stops.last.id.to_s)
      expect(attributes[:title]).to be_nil
    end

    it 'returns a 200 response that is a stop when request is authenticated by a tour author' do
      tour = create(:tour)
      tour.update(published: false)
      Stop.all.each { |stop| tour.stops << stop }
      tour.stops.first.update(tours: [tour])
      user = create(:user)
      user.update(super: false)
      user.tours << tour
      user.tour_sets = []
      signed_cookie(user)
      get :show, params: { tenant: Apartment::Tenant.current, id: tour.stops.first.id }
      expect(response.status).to eq(200)
      expect(attributes[:title]).to eq(tour.stops.first.title)
    end

    it 'returns a 200 response that is a stop when request is authenticated by a tenant admin' do
      tour = create(:tour)
      tour.update(published: false)
      Stop.all.each { |stop| tour.stops << stop }
      tour.stops.first.update(tours: [tour])
      user = create(:user)
      user.update(super: false)
      user.tours = []
      user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
      signed_cookie(user)
      get :show, params: { tenant: Apartment::Tenant.current, id: tour.stops.first.id }
      expect(response.status).to eq(200)
      expect(attributes[:title]).to eq(tour.stops.first.title)
    end

    it 'returns a 200 response that is a stop when request is authenticated by a super user' do
      tour = create(:tour)
      tour.update(published: false)
      Stop.all.each { |stop| tour.stops << stop }
      tour.stops.first.update(tours: [tour])
      user = create(:user)
      user.update(super: true)
      user.tours = []
      user.tour_sets = []
      signed_cookie(user)
      get :show, params: { tenant: Apartment::Tenant.current, id: tour.stops.first.id }
      expect(response.status).to eq(200)
      expect(attributes[:title]).to eq(tour.stops.first.title)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'return 401 when unauthenciated' do
          post :create, params: { data: { type: 'stops', attributes: { title: 'Burrito Stop' } }, tenant: Apartment::Tenant.current }
          expect(response.status).to eq(401)
        end

      it 'return 401 when authenciated but not an admin for current tenant' do
        user = create(:user)
        user.update(super: false)
        user.tour_sets = []
        user.tours = []
        signed_cookie(user)
        post :create, params: { data: { type: 'stops', attributes: { title: 'Burrito Stop' } }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(401)
      end

      it 'return 201 when authenciated but an admin for current tenant' do
        user = create(:user)
        user.update(super: false)
        user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
        signed_cookie(user)
        original_stop_count = Stop.count
        post :create, params: { data: { type: 'stops', attributes: { title: 'Burrito Stop' } }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(201)
        expect(attributes[:title]).to eq('Burrito Stop')
        expect(Stop.count).to eq(original_stop_count + 1)
      end

      it 'return 201 when authenciated by super' do
        user = create(:user)
        user.tour_sets = []
        user.update(super: true)
        signed_cookie(user)
        original_stop_count = Stop.count
        post :create, params: { data: { type: 'stops', attributes: { title: 'Taco Stop' } }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(201)
        expect(attributes[:title]).to eq('Taco Stop')
        expect(Stop.count).to eq(original_stop_count + 1)
      end

      it 'return 201 when authenciated by a tour author' do
        user = create(:user)
        user.tour_sets = []
        user.tours << Tour.last
        user.update(super: false)
        signed_cookie(user)
        original_stop_count = Stop.count
        post :create, params: { data: { type: 'stops', attributes: { title: 'Elmyr' } }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(201)
        expect(attributes[:title]).to eq('Elmyr')
        expect(Stop.count).to eq(original_stop_count + 1)
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      it 'return 401 when unauthenciated' do
        create(:tour)
        post :update, params: { id: Stop.last.id, data: { type: 'stops', attributes: { title: 'Burrito Stop' } }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(401)
      end

      it 'return 401 when authenciated but not an admin for current tenant' do
        create(:tour, published: false)
        user = create(:user)
        user.update(super: false)
        user.tour_sets = []
        user.tours = []
        signed_cookie(user)
        post :update, params: { id: Stop.first.id, data: { type: 'stops', attributes: { title: 'Burrito Stop' } }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(401)
      end

      it 'return 200 and updated tour when authenciated but an admin for current tenant' do
        create(:tour, published: false)
        user = create(:user)
        user.update(super: false)
        user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
        signed_cookie(user)
        original_stop_title = Stop.last.title
        new_title = Faker::Name.unique.name
        post :update, params: { id: Stop.first.id, data: { type: 'stops', attributes: { title: new_title } }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(200)
        expect(attributes[:title]).not_to eq(original_stop_title)
        expect(attributes[:title]).to eq(new_title)
        expect(Stop.first.title).to eq(new_title)
      end

      it 'return 200 and updated tour when authenciated by super' do
        tour = create(:tour)
        tour.stops << create_list(:stop, 4)
        user = create(:user)
        user.tour_sets = []
        user.update(super: true)
        signed_cookie(user)
        original_stop_title = Stop.last.title
        new_title = Faker::Name.unique.name
        post :update, params: { id: Stop.last.id, data: { type: 'stops', attributes: { title: new_title } }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(200)
        expect(attributes[:title]).not_to eq(original_stop_title)
        expect(attributes[:title]).to eq(new_title)
        expect(Stop.last.title).to eq(new_title)
      end

      it 'return 200 and updated tour when authenciated by tour author' do
        tour = create(:tour)
        user = create(:user)
        user.update(super: false)
        user.tour_sets = []
        user.tours << tour
        signed_cookie(user)
        original_stop_title = Stop.last.title
        new_title = Faker::Name.unique.name
        post :update, params: { id: Stop.first.id, data: { type: 'stops', attributes: { title: new_title } }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(200)
        expect(attributes[:title]).not_to eq(original_stop_title)
        expect(attributes[:title]).to eq(new_title)
        expect(Stop.first.title).to eq(new_title)
      end
    end

    # context 'with invalid params' do
    #   it 'renders a JSON response with errors for the tour' do
    #     tour = Stop.create! valid_attributes

    #     put :update, params: { id: tour.to_param, tour: invalid_attributes }
    #     expect(response).to have_http_status(:unprocessable_entity)
    #     expect(response.content_type).to eq('application/json')
    #   end
    # end
  end

  describe 'DELETE #destroy' do
    it 'return 401 when unauthenciated' do
      create(:tour)
      post :destroy, params: { id: Stop.first.id, tenant: Apartment::Tenant.current }
      expect(response.status).to eq(401)
    end

    it 'return 401 when authenciated but not an admin for current tenant' do
      tour = create(:tour)
      user = create(:user)
      user.update(super: false)
      user.tour_sets = []
      signed_cookie(user)
      post :destroy, params: { id: Stop.first.id, tenant: Apartment::Tenant.current }
      expect(response.status).to eq(401)
    end

    it 'return 204 and one less tour when authenciated but an admin for current tenant' do
      tour = create(:tour)
      user = create(:user)
      user.update(super: false)
      user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
      signed_cookie(user)
      stop_count = Stop.count
      Stop.last.update(tours: [])
      post :destroy, params: { id: Stop.last.id, tenant: Apartment::Tenant.current }
      Stop.last.update(tours: [])
      expect(response.status).to eq(204)
      expect(Stop.count).to eq(stop_count - 1)
    end

    it 'return 204 and one less tour when authenciated by super' do
      tour = create(:tour)
      user = create(:user)
      user.tour_sets = []
      user.update(super: true)
      signed_cookie(user)
      Stop.first.update(tours: [])
      stop_count = Stop.count
      post :destroy, params: { id: Stop.first.id, tenant: Apartment::Tenant.current }
      expect(response.status).to eq(204)
      expect(Stop.count).to eq(stop_count - 1)
    end

    it 'return 204 and one less stop when authenciated by tour author and Stop does not belong to a Tour' do
      tour = create(:tour)
      user = create(:user)
      user.update(super: false)
      user.tour_sets = []
      user.tours << tour
      signed_cookie(user)
      Stop.last.update(tours: [])
      stop_count = Stop.count
      post :destroy, params: { id: Stop.last.id, tenant: Apartment::Tenant.current }
      expect(response.status).to eq(204)
      expect(Stop.count).to eq(stop_count - 1)
    end

    it 'return 405 and does not delete Stop when Stop belongs to a Tour and requested by super' do
      tour = create(:tour)
      user = create(:user)
      user.update(super: true)
      Stop.last.tours << tour if Stop.last.tours.empty?
      signed_cookie(user)
      stop_count = Stop.count
      post :destroy, params: { id: Stop.last.id, tenant: Apartment::Tenant.current }
      expect(response.status).to eq(405)
      expect(Stop.count).to eq(stop_count)
    end
  end
end
