# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V3::TourStopsController, type: :controller do
  def data(tour, stop, position = 1)
    {
      type: 'tour_stops',
      attributes: { position: position },
      relationships: {
        tour: { data: { type: 'tours', id: tour.id } },
        stop: { data: { type: 'stops', id: stop.id } }
      }
    }
  end

  describe 'GET #index' do
    it 'returns a 200 response and empty tour when none are part of a published tour' do
      Tour.all.each { |tour| tour.update(published: false) }
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(json).to be_empty
      expect(response.status).to eq(200)
    end

    it 'returns a 200 response and only tour stops that are part of a published tour' do
      create_list(:tour_with_stops, 5, theme: create(:theme), mode: create(:mode))
      Tour.first.update(published: true) if Tour.published.empty?
      Tour.last.update(published: false) if Tour.published.count == Tour.count
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(response.status).to eq(200)
      expect(json.count).to eq(Tour.published.map { |tour| tour.tour_stops.count }.sum)
    end

    it 'returns a 200 response when requeted by slug' do
      tour = create(:tour_with_stops)
      tour.update(published: true)
      get :index, params: { tenant: Apartment::Tenant.current, slug: tour.tour_stops.first.stop.slug, tour: tour.id }
      expect(response.status).to eq(200)
      expect(included.first[:attributes][:title]).to eq(tour.tour_stops.first.stop.title)
    end

    it 'returns a 200 response when request is authenticated by tenant admin and tour is unpublished' do
      tour = create(:tour_with_stops, published: false)
      tour.update(published: false)
      user = create(:user)
      user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
      signed_cookie(user)
      get :index, params: { tenant: Apartment::Tenant.current, slug: tour.tour_stops.first.stop.slug, tour: tour.id }
      expect(response.status).to eq(200)
      expect(included.first[:attributes][:title]).to eq(tour.tour_stops.first.stop.title)
    end

    it 'returns a 200 response when request is authenticated by tour author and tour is unpublished' do
      tour = create(:tour_with_stops, published: false)
      tour.update(published: false)
      user = create(:user)
      user.tour_sets = []
      user.tours << tour
      signed_cookie(user)
      get :index, params: { tenant: Apartment::Tenant.current, slug: tour.tour_stops.first.stop.slug, tour: tour.id }
      expect(response.status).to eq(200)
      expect(included.first[:attributes][:title]).to eq(tour.tour_stops.first.stop.title)
    end
  end

  describe 'GET #show' do
    it 'returns a 200 response' do
      tours = create(:tour_with_stops)
      tour = Tour.last
      tour.update(published: true)
      get :show, params: { tenant: Apartment::Tenant.current, id: tour.tour_stops.last.id }
      expect(response.status).to eq(200)
      expect(relationships[:tour][:data][:id]).to eq(tour.id.to_s)
    end

    it 'returns a 200 response when request is authenticated by tour author and tour is unpublished' do
      tour = create(:tour_with_stops)
      tour.update(published: false)
      user = create(:user)
      user.tour_sets = []
      user.tours << tour
      signed_cookie(user)
      get :show, params: { tenant: Apartment::Tenant.current, id: tour.tour_stops.last.id }
      expect(response.status).to eq(200)
      expect(relationships[:tour][:data][:id]).to eq(tour.id.to_s)
    end

    it 'returns a 200 response when request is authenticated by tenant admin and tour is unpublished' do
      tour = create(:tour_with_stops)
      tour.update(published: false)
      user = create(:user)
      user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
      signed_cookie(user)
      get :show, params: { tenant: Apartment::Tenant.current, id: tour.tour_stops.last.id }
      expect(response.status).to eq(200)
      expect(relationships[:tour][:data][:id]).to eq(tour.id.to_s)
    end

    it 'returns a 200 response and empty json when tour is unpublished and request is not authenticated' do
      tour = create(:tour_with_stops)
      tour.update(published: false)
      get :show, params: { tenant: Apartment::Tenant.current, id: tour.tour_stops.last.id }
      expect(response.status).to eq(200)
      expect(json).to be_empty
    end

    it 'returns a 200 response and empty json when tour is unpublished and request is authenticated by someone who is nither a tenant admin or tour author' do
      tour = create(:tour_with_stops)
      tour.update(published: false)
      user = create(:user)
      user.tours = []
      user.tour_sets = []
      signed_cookie(user)
      get :show, params: { tenant: Apartment::Tenant.current, id: tour.tour_stops.last.id }
      expect(response.status).to eq(200)
      expect(json).to be_empty
    end
  end

  # TourStop objects are NOT created via tha API. Every test should return 401
  describe 'POST #create' do
    context 'with valid params' do
      it 'return 401 when unauthenciated' do
        tour = create(:tour)
        stop = create(:stop)
        post :create, params: { data: data(tour, stop), tenant: TourSet.first.subdir }
        expect(response.status).to eq(401)
      end

      it 'return 401 when authenciated but not an admin for current tenant' do
        tour = create(:tour)
        stop = create(:stop)
        original_tour_stop_count = TourStop.count
        user = create(:user)
        user.update(super: false)
        user.tour_sets = []
        user.tours = []
        signed_cookie(user)
        post :create, params: { data:  data(tour, stop), tenant: Apartment::Tenant.current }
        expect(response.status).to eq(401)
        expect(original_tour_stop_count).to eq(TourStop.count)
      end

      it 'return 401 when authenciated but an admin for current tenant' do
        tour = create(:tour)
        stop = create(:stop)
        original_tour_stop_count = TourStop.count
        user = create(:user)
        user.update(super: false)
        user.tours = []
        user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
        signed_cookie(user)
        post :create, params: { data:  data(tour, stop), tenant: Apartment::Tenant.current }
        expect(response.status).to eq(401)
        expect(original_tour_stop_count).to eq(TourStop.count)
      end

      it 'return 401 when authenciated by super' do
        tour = create(:tour)
        stop = create(:stop)
        original_tour_stop_count = TourStop.count
        user = create(:user)
        user.tours = []
        user.tour_sets = []
        user.update(super: true)
        signed_cookie(user)
        post :create, params: { data:  data(tour, stop), tenant: Apartment::Tenant.current }
        expect(response.status).to eq(401)
        expect(original_tour_stop_count).to eq(TourStop.count)
      end

      it 'return 401 when authenciated by tour author' do
        tour = create(:tour)
        stop = create(:stop)
        original_tour_stop_count = TourStop.count
        user = create(:user)
        user.tours << tour
        user.tour_sets = []
        user.update(super: false)
        signed_cookie(user)
        post :create, params: { data:  data(tour, stop), tenant: Apartment::Tenant.current }
        expect(response.status).to eq(401)
        expect(original_tour_stop_count).to eq(TourStop.count)
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      it 'return 401 when unauthenciated' do
        tour = create(:tour)
        stop = create(:stop)
        tour.stops << stop
        request_data = data(tour, stop, 4)
        request_data[:id] = TourStop.find_by(tour: tour, stop: stop).id
        post :update, params: { id: request_data[:id], data: request_data, tenant: TourSet.first.subdir }
        expect(response.status).to eq(401)
      end

      it 'return 401 when authenciated but not an admin for current tenant' do
        tour = create(:tour)
        stop = create(:stop)
        tour.stops << stop
        user = create(:user)
        user.update(super: false)
        user.tour_sets = []
        user.tours = []
        signed_cookie(user)
        request_data = data(tour, stop, 5)
        request_data[:id] = TourStop.find_by(tour: tour, stop: stop).id
        post :update, params: { id: request_data[:id], data: request_data, tenant: TourSet.first.subdir }
        expect(response.status).to eq(401)
      end

      it 'return 200 and updated tour when authenciated but an admin for current tenant' do
        tour = create(:tour)
        stops = create_list(:stop, 5)
        stops.each { |stop| tour.stops << stop }
        tour.save
        stop = Stop.find(stops.first.id)
        tour.stops << stop
        user = create(:user)
        user.update(super: false)
        user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
        user.tours = []
        signed_cookie(user)
        tour_stop = TourStop.find_by(tour: tour, stop: stop)
        tour_stop.update(position: 2)
        expect(TourStop.find(tour_stop.id).position).to eq(2)
        request_data = data(tour, stop, 5)
        request_data[:id] = tour_stop.id
        post :update, params: { id: tour_stop.id, data: request_data, tenant: TourSet.first.subdir }
        expect(response.status).to eq(200)
        expect(attributes[:position]).not_to eq('5')
        expect(TourStop.find(tour_stop.id).position).to eq(5)
      end

      it 'return 200 and updated tour when authenciated by super' do
        tour = create(:tour)
        stops = create_list(:stop, 5)
        stops.each { |stop| tour.stops << stop }
        tour.save
        stop = Stop.find(stops.first.id)
        tour.stops << stop
        user = create(:user)
        user.update(super: true)
        user.tour_sets = []
        user.tours = []
        signed_cookie(user)
        tour_stop = TourStop.find_by(tour: tour, stop: stop)
        tour_stop.update(position: 3)
        expect(TourStop.find(tour_stop.id).position).to eq(3)
        request_data = data(tour, stop, 4)
        request_data[:id] = tour_stop.id
        post :update, params: { id: tour_stop.id, data: request_data, tenant: TourSet.first.subdir }
        expect(response.status).to eq(200)
        expect(attributes[:position]).not_to eq('4')
        expect(TourStop.find(tour_stop.id).position).to eq(4)
      end

      it 'return 200 and updated tour when authenciated by tour author' do
        tour = create(:tour)
        stops = create_list(:stop, 5)
        stops.each { |stop| tour.stops << stop }
        tour.save
        stop = Stop.find(stops.first.id)
        tour.stops << stop
        user = create(:user)
        user.update(super: false)
        user.tour_sets = []
        user.tours << tour
        signed_cookie(user)
        tour_stop = TourStop.find_by(tour: tour, stop: stop)
        tour_stop.update(position: 6)
        expect(TourStop.find(tour_stop.id).position).to eq(6)
        request_data = data(tour, stop, 1)
        request_data[:id] = tour_stop.id
        post :update, params: { id: tour_stop.id, data: request_data, tenant: TourSet.first.subdir }
        expect(response.status).to eq(200)
        expect(attributes[:position]).not_to eq('1')
        expect(TourStop.find(tour_stop.id).position).to eq(1)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'return 401 when unauthenciated' do
      tour = create(:tour)
      stop = create(:stop)
      tour.stops << stop
      tour_stop = TourStop.find_by(tour: tour, stop: stop)
      post :destroy, params: { id: tour_stop.id, tenant: TourSet.first.subdir }
      expect(response.status).to eq(401)
    end

    it 'return 401 when authenciated but not an admin for current tenant' do
      tour = create(:tour)
      stop = create(:stop)
      tour.stops << stop
      tour_stop = TourStop.find_by(tour: tour, stop: stop)
      user = create(:user)
      user.update(super: false)
      user.tour_sets = []
      signed_cookie(user)
      post :destroy, params: { id: tour_stop.id, tenant: TourSet.first.subdir }
      expect(response.status).to eq(401)
    end

    it 'return 401 and one less tour when authenciated but an admin for current tenant' do
      tour = create(:tour)
      stop = create(:stop)
      tour.stops << stop
      tour_stop = TourStop.find_by(tour: tour, stop: stop)
      user = create(:user)
      user.update(super: false)
      user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
      signed_cookie(user)
      tour_count = Tour.count
      post :destroy, params: { id: tour_stop.id, tenant: Apartment::Tenant.current }
      expect(response.status).to eq(401)
      expect(Tour.count).to eq(tour_count)
    end

    it 'return 401 and one less tour when authenciated by super' do
      tour = create(:tour)
      stop = create(:stop)
      tour.stops << stop
      tour_stop = TourStop.find_by(tour: tour, stop: stop)
      user = create(:user)
      user.tour_sets = []
      user.update(super: true)
      signed_cookie(user)
      tour_count = Tour.count
      post :destroy, params: { id: tour_stop.id, tenant: Apartment::Tenant.current }
      expect(response.status).to eq(401)
      expect(Tour.count).to eq(tour_count)
    end

    it 'return 401 and one less tour when authenciated by tour author' do
      tour = create(:tour)
      stop = create(:stop)
      tour.stops << stop
      tour_stop = TourStop.find_by(tour: tour, stop: stop)
      user = create(:user)
      user.update(super: false)
      user.tour_sets = []
      user.tours << tour
      signed_cookie(user)
      new_title = Faker::Name.unique.name
      tour_count = Tour.count
      post :destroy, params: { id: tour_stop.id, tenant: Apartment::Tenant.current }
      expect(response.status).to eq(401)
      expect(Tour.count).to eq(tour_count)
    end
  end
end
