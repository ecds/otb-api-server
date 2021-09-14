# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V3::ToursController, type: :controller do
  describe 'GET #index' do
    it 'returns a 200 response and empty tour when none found' do
      StopSlug.all.each { |t| t.delete }
      Stop.all.each { |t| t.delete }
      Tour.all.each { |t| t.delete }
      get :index, params: { tenant: 'public' }
      expect(json).to be_empty
      expect(response.status).to eq(200)
    end

    it 'returns a 200 response' do
      tour = create(:tour)
      tour.update(published: true)
      get :index, params: { tenant: tour.tenant }
      expect(response.status).to eq(200)
      expect(json.count).to eq(Tour.published.count)
    end

    it 'returns a 200 response when requeted by slug' do
      tour = create(:tour)
      tour.update(published: true)
      get :index, params: { tenant: tour.tenant, slug: tour.slug }
      expect(response.status).to eq(200)
      expect(attributes[:title]).to eq(tour.title)
    end

    # This is for when an authenticated person is viewing an unpublished tour.
    # This situation occurs when Ember FastBoot tries to pre-render an unpublished
    # tour. FastBoot does not have credentials to send. A 404 response causes
    # FastBoot to throw an error and prevents the client from rendering.
    it 'returns a 200 response and empty tour when tour is not published' do
      tour = create(:tour)
      tour.update(published: false)
      get :index, params: { tenant: tour.tenant, slug: tour.slug }
      expect(response.status).to eq(200)
      expect(attributes[:title]).not_to eq(tour.title)
      expect(attributes[:title]).to eq('....')
    end

    it 'returns a 200 response when request is authenticated by tenant admin and tour is unpublished' do
      tour = create(:tour, published: false)
      tour.update(published: false)
      user = create(:user)
      user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
      signed_cookie(user)
      get :index, params: { tenant: tour.tenant, slug: tour.slug }
      expect(response.status).to eq(200)
      expect(attributes[:title]).to eq(tour.title)
    end

    it 'returns a 200 response when request is authenticated by tour author and tour is unpublished' do
      tour = create(:tour, published: false)
      tour.update(published: false)
      user = create(:user)
      user.tour_sets = []
      user.tours << tour
      signed_cookie(user)
      get :index, params: { tenant: tour.tenant, slug: tour.slug }
      expect(response.status).to eq(200)
      expect(attributes[:title]).to eq(tour.title)
    end

    it 'returns all Tour objects when requested by tenant admin' do
      create_list(:tour, rand(4..5))
      user = create(:user, super: false)
      user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
      signed_cookie(user)
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(json.count).to eq(Tour.count)
    end

    it 'returns only tours where requester is an author' do
      Tour.first.update(published: true)
      new_tours = create_list(:tour, rand(4..6), published: false)
      user = create(:user, super: false)
      user.tour_sets = []
      user.tours << [Tour.published.first, new_tours.first, new_tours.last]
      signed_cookie(user)
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(json.count).to eq((user.tours + Tour.published).uniq.count)
      expect(json.count).to be < Tour.count
    end
  end

  describe 'GET #show' do
    it 'returns a 200 response' do
      tour = create(:tour, published: true, mode: Mode.find_by(title: 'BICYCLING'), stops: create_list(:stop, rand(3..5)))
      get :show, params: { tenant: tour.tenant, id: tour.id }
      expect(response.status).to eq(200)
      expect(attributes[:title]).to eq(tour.title)
      expect(attributes[:est_time]).to eq('About 2 hours bicycling')
    end

    # This is for when an authenticated person is viewing an unpublished tour.
    # This situation occurs when Ember FastBoot tries to pre-render an unpublished
    # tour. FastBoot does not have credentials to send. A 404 response causes
    # FastBoot to throw an error and prevents the client from rendering.
    it 'returns a 200 response and empty tour when tour is not published' do
      tour = create(:tour)
      tour.update(published: false)
      cookies[:auth] = nil
      get :show, params: { tenant: tour.tenant, id: tour.id }
      expect(response.status).to eq(200)
      expect(attributes[:title]).not_to eq(tour.title)
      expect(attributes[:title]).to eq('....')
    end

    it 'returns a 200 response when request is authenticated by tour author and tour is unpublished' do
      tour = create(:tour, published: false)
      tour.update(published: false, media: create_list(:medium, 3))
      user = create(:user)
      user.tour_sets = []
      user.tours << tour
      signed_cookie(user)
      get :show, params: { tenant: tour.tenant, id: tour.id }
      expect(response.status).to eq(200)
      expect(attributes[:title]).to eq(tour.title)
    end

    it 'returns a 200 response when request is authenticated by tenant admin and tour is unpublished' do
      tour = create(:tour, published: false, medium: create(:medium))
      tour.update(published: false)
      user = create(:user)
      user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
      signed_cookie(user)
      get :show, params: { tenant: tour.tenant, id: tour.id }
      expect(response.status).to eq(200)
      expect(attributes[:title]).to eq(tour.title)
    end

    it 'retuns a tour with center lat/lng based on request' do
      request.env['ipinfo'] = MockIpinfo.new
      tour = create(:tour, stops: [])
      user = create(:user, super: true)
      signed_cookie(user)
      get :show, params: { tenant: Apartment::Tenant.current, id: tour.id }
      expect(attributes[:bounds][:centerLat]).not_to eq(33.75432)
      expect(attributes[:bounds][:centerLng]).not_to eq(-84.38979)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'return 401 when unauthenciated' do
          post :create, params: { data: { type: 'tours', attributes: { title: 'Burrito Tour' } }, tenant: TourSet.first.subdir }
          expect(response.status).to eq(401)
        end

      it 'return 401 when authenciated but not an admin for current tenant' do
        user = create(:user)
        user.update(super: false)
        user.tour_sets = []
        signed_cookie(user)
        post :create, params: { data: { type: 'tours', attributes: { title: 'Burrito Tour' } }, tenant: TourSet.first.subdir }
        expect(response.status).to eq(401)
      end

      it 'return 201 when authenciated but an admin for current tenant' do
        user = create(:user)
        user.update(super: false)
        user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
        signed_cookie(user)
        original_tour_count = Tour.count
        post :create, params: { data: { type: 'tours', attributes: { title: 'Burrito Tour' } }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(201)
        expect(Tour.count).to eq(original_tour_count + 1)
      end

      it 'return 201 when authenciated by super' do
        user = create(:user)
        user.tour_sets = []
        user.update(super: true)
        signed_cookie(user)
        original_tour_count = Tour.count
        post :create, params: { data: { type: 'tours', attributes: { title: 'Burrito Tour' } }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(201)
        expect(Tour.count).to eq(original_tour_count + 1)
      end

      it 'returns 422 when invalid attributes' do
        user = create(:user, super: true)
        signed_cookie(user)
        original_tour_count = Tour.count
        post :create, params: { data: { type: 'tours', attributes: { title: nil } }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(422)
        expect(Tour.count).to eq(original_tour_count)
        expect(errors).to include('Title can\'t be blank')
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      it 'return 401 when unauthenciated' do
        tour = create(:tour, published: false)
        post :update, params: { id: tour.id, data: { type: 'tours', attributes: { title: 'Burrito Tour' } }, tenant: TourSet.first.subdir }
        expect(response.status).to eq(401)
      end

      it 'return 401 when authenciated but not an admin for current tenant' do
        tour = create(:tour, published: false)
        user = create(:user)
        user.update(super: false)
        user.tour_sets = []
        signed_cookie(user)
        post :update, params: { id: tour.id, data: { type: 'tours', attributes: { title: 'Burrito Tour' } }, tenant: TourSet.first.subdir }
        expect(response.status).to eq(401)
      end

      it 'return 200 and updated tour when authenciated but an admin for current tenant' do
        tour = create(:tour, published: false)
        user = create(:user)
        user.update(super: false)
        user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
        signed_cookie(user)
        new_title = Faker::Name.unique.name
        post :update, params: { id: tour.id, data: { type: 'tours', attributes: { title: new_title } }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(200)
        expect(attributes[:title]).not_to eq(tour.title)
        expect(attributes[:title]).to eq(new_title)
        expect(Tour.find(tour.id).title).to eq(new_title)
      end

      it 'return 200 and updated tour when authenciated by super' do
        tour = create(:tour, published: false)
        user = create(:user)
        user.tour_sets = []
        user.update(super: true)
        signed_cookie(user)
        new_title = Faker::Name.unique.name
        post :update, params: { id: tour.id, data: { type: 'tours', attributes: { title: new_title } }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(200)
        expect(attributes[:title]).not_to eq(tour.title)
        expect(attributes[:title]).to eq(new_title)
        expect(Tour.find(tour.id).title).to eq(new_title)
      end

      it 'return 200 and updated tour when authenciated by tour author' do
        tour = create(:tour, published: false)
        user = create(:user)
        user.update(super: false)
        user.tour_sets = []
        user.tours << tour
        signed_cookie(user)
        new_title = Faker::Name.unique.name
        post :update, params: { id: tour.id, data: { type: 'tours', attributes: { title: new_title } }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(200)
        expect(attributes[:title]).not_to eq(tour.title)
        expect(attributes[:title]).to eq(new_title)
        expect(Tour.find(tour.id).title).to eq(new_title)
      end

      it 'returns 200 and adds stop to a tour' do
        tour = create(:tour)
        create_list(:stop, 5)
        Stop.all.each { |stop| tour.stops << stop }
        serialized_tour = JSON.parse(ActiveModelSerializers::Adapter::JsonApi.new(V3::TourSerializer.new(tour)).to_json).with_indifferent_access
        original_stop_count = serialized_tour[:data][:relationships][:stops][:data].count
        original_tour_stop_count = serialized_tour[:data][:relationships][:tour_stops][:data].count
        expect(original_stop_count).to be >= 5
        expect(original_tour_stop_count).to be >= 5
        expect(original_stop_count).to eq(original_tour_stop_count)
        expect(original_stop_count).to eq(tour.stops.count)
        expect(original_tour_stop_count).to eq(tour.tour_stops.count)
        stop = create(:stop)
        expect(serialized_tour[:data][:relationships][:stops][:data].map { |s| s['id'] }).not_to include(stop.id.to_s)
        serialized_tour[:data][:relationships][:stops][:data].push(JSON.parse("{\"id\":\"#{stop.id}\",\"type\":\"stops\"}"))
        expect(serialized_tour[:data][:relationships][:stops][:data].count).to eq(original_stop_count + 1)
        expect(serialized_tour[:data][:relationships][:stops][:data].map { |s| s['id'] }).to include(stop.id.to_s)
        expect(tour.stops).not_to include(stop)
        user = create(:user)
        user.update(super: false)
        user.tour_sets = []
        user.tours << tour
        signed_cookie(user)
        post :update, params: { id: tour.id, data: serialized_tour[:data], tenant: Apartment::Tenant.current }
        expect(response.status).to eq(200)
        expect(Tour.find(tour.id).stops).to include(stop)
        expect(relationships[:stops][:data].count).to eq(original_stop_count + 1)
        expect(relationships[:tour_stops][:data].count).to eq(original_tour_stop_count + 1)
      end

      it 'returns 200 and removes a stop from a tour' do
        tour = create(:tour)
        create_list(:stop, 5)
        Stop.all.each { |stop| tour.stops << stop }
        serialized_tour = JSON.parse(ActiveModelSerializers::Adapter::JsonApi.new(V3::TourSerializer.new(tour)).to_json).with_indifferent_access
        original_stop_count = serialized_tour[:data][:relationships][:stops][:data].count
        original_tour_stop_count = serialized_tour[:data][:relationships][:tour_stops][:data].count
        expect(original_stop_count).to be >= 5
        expect(original_tour_stop_count).to be >= 5
        expect(original_stop_count).to eq(original_tour_stop_count)
        expect(original_stop_count).to eq(tour.stops.count)
        expect(original_tour_stop_count).to eq(tour.tour_stops.count)
        expect(serialized_tour[:data][:relationships][:stops][:data].count).to eq(original_stop_count)
        stop = serialized_tour[:data][:relationships][:stops][:data].pop
        expect(serialized_tour[:data][:relationships][:stops][:data].map { |s| s['id'] }).not_to include(stop[:id])
        expect(serialized_tour[:data][:relationships][:stops][:data].count).to eq(original_stop_count - 1)
        expect(tour.stops).to include(Stop.find(stop[:id]))
        user = create(:user)
        user.update(super: false)
        user.tour_sets = []
        user.tours << tour
        signed_cookie(user)
        post :update, params: { id: tour.id, data: serialized_tour[:data], tenant: Apartment::Tenant.current }
        expect(response.status).to eq(200)
        expect(Tour.find(tour.id).stops).not_to include(Stop.find(stop[:id]))
        expect(relationships[:stops][:data].count).to eq(original_stop_count - 1)
        expect(relationships[:tour_stops][:data].count).to eq(original_tour_stop_count - 1)
      end

      it 'returns 422 when title in nil' do
        tour = create(:tour)
        serialized_tour = JSON.parse(ActiveModelSerializers::Adapter::JsonApi.new(V3::TourSerializer.new(tour)).to_json).with_indifferent_access
        serialized_tour[:data][:attributes][:title] = nil
        user = create(:user, super: true)
        signed_cookie(user)
        post :update, params: { id: tour.id, data: serialized_tour[:data], tenant: Apartment::Tenant.current }
        expect(response.status).to eq(422)
        expect(errors).to include('Title can\'t be blank')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'return 401 when unauthenciated' do
      tour = create(:tour, published: false)
      post :destroy, params: { id: tour.id, tenant: TourSet.first.subdir }
      expect(response.status).to eq(401)
    end

    it 'return 401 when authenciated but not an admin for current tenant' do
      tour = create(:tour, published: false)
      user = create(:user)
      user.update(super: false)
      user.tour_sets = []
      signed_cookie(user)
      post :destroy, params: { id: tour.id, tenant: TourSet.first.subdir }
      expect(response.status).to eq(401)
    end

    it 'return 204 and one less tour when authenciated but an admin for current tenant' do
      tour = create(:tour, published: false)
      user = create(:user)
      user.update(super: false)
      user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
      signed_cookie(user)
      tour_count = Tour.count
      post :destroy, params: { id: tour.id, tenant: Apartment::Tenant.current }
      expect(response.status).to eq(204)
      expect(Tour.count).to eq(tour_count - 1)
    end

    it 'return 204 and one less tour when authenciated by super' do
      tour = create(:tour, published: false)
      user = create(:user)
      user.tour_sets = []
      user.update(super: true)
      signed_cookie(user)
      tour_count = Tour.count
      post :destroy, params: { id: tour.id, tenant: Apartment::Tenant.current }
      expect(response.status).to eq(204)
      expect(Tour.count).to eq(tour_count - 1)
    end

    it 'return 204 and one less tour when authenciated by tour author' do
      tour = create(:tour, published: false)
      user = create(:user)
      user.update(super: false)
      user.tour_sets = []
      user.tours << tour
      signed_cookie(user)
      tour_count = Tour.count
      post :destroy, params: { id: tour.id, tenant: Apartment::Tenant.current }
      expect(response.status).to eq(204)
      expect(Tour.count).to eq(tour_count - 1)
    end
  end
end
