# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(V4::Admin::ToursController, type: :controller) do
  let(:tour_set) { create(:tour_set) }

  def clean_reindex
    begin
      Tour.search_index.delete
    rescue StandardError
      nil
    end
    Tour.reindex
  end

  describe 'GET #index' do
    it 'returns 401 when unauthenticated' do
      get :index, params: { tenant: tour_set.subdir }
      expect(response.status).to(eq(401))
    end

    it 'returns all tours when super user' do
      user = create(:user, super: true)
      signed_cookie(user)
      Apartment::Tenant.switch!(tour_set.subdir)
      create_list(:tour, 4)
      clean_reindex
      get :index, params: { tenant: tour_set.subdir }
      expect(v4_json.count).to(eq(Tour.count))
    end

    it 'returns all tours when tour set admin' do
      user = create(:user, super: false)
      Apartment::Tenant.switch!(tour_set.subdir)
      create_list(:tour, 4)
      user.tour_sets << tour_set
      signed_cookie(user)
      clean_reindex
      get :index, params: { tenant: tour_set.subdir }
      expect(v4_json.count).to(eq(Tour.count))
    end

    it 'returns only tours assigned to user' do
      user = create(:user, super: false)
      signed_cookie(user)
      Apartment::Tenant.switch!(tour_set.subdir)
      tours = create_list(:tour, 4)
      user.tours << [tours.first, tours.last]
      clean_reindex
      get :index, params: { tenant: tour_set.subdir }
      expect(v4_json.count).to(eq(2))
      expect(v4_json.count).not_to(eq(Tour.count))
    end

    it 'returns empty list when no tours' do
      user = create(:user, super: true)
      signed_cookie(user)
      Apartment::Tenant.switch!(tour_set.subdir)
      expect(Tour.count).to(be_zero)
      clean_reindex
      get :index, params: { tenant: tour_set.subdir }
      expect(v4_json.count).to(be_zero)
    end

    it 'returns list of all tours if all param is present' do
      user = create(:user, super: false)
      signed_cookie(user)
      Apartment::Tenant.switch!(tour_set.subdir)
      create_list(:tour, 3)
      clean_reindex
      get :index, params: { tenant: tour_set.subdir, all: true }
      expect(v4_json.count).to(eq(Tour.count))
      expect(v4_json.count).to(be > 0)
    end
  end

  describe 'GET #show' do
    it 'returns 401 when unauthenticated' do
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      clean_reindex
      get :show, params: { tenant: tour_set.subdir, id: tour.id }
      expect(response.status).to(eq(401))
    end

    it 'returns 200 and tour when authenticated as super' do
      user = create(:user, super: true)
      signed_cookie(user)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      clean_reindex
      get :show, params: { tenant: tour_set.subdir, id: tour.id }
      expect(response.status).to(eq(200))
      expect(v4_json[:title]).to(eq(tour.title))
    end

    it 'returns 200 a tour when authenticated as site owner' do
      user = create(:user, super: false)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      user.tour_sets << tour_set
      signed_cookie(user)
      clean_reindex
      get :show, params: { tenant: tour_set.subdir, id: tour.id }
      expect(response.status).to(eq(200))
      expect(v4_json[:title]).to(eq(tour.title))
    end

    it 'returns 200 a tour when authenticated as tour author' do
      user = create(:user, super: false)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      user.tours << tour
      signed_cookie(user)
      clean_reindex
      get :show, params: { tenant: tour_set.subdir, id: tour.id }
      expect(response.status).to(eq(200))
      expect(v4_json[:id]).to(eq(tour.id))
    end

    it 'returns 401 when authenticated as site owner but requesting tour for different site' do
      other_tour_set = create(:tour_set)
      user = create(:user, super: false)
      Apartment::Tenant.switch!(other_tour_set.subdir)
      tour = create(:tour, published: false)
      user.tour_sets << tour_set
      signed_cookie(user)
      clean_reindex
      get :show, params: { tenant: other_tour_set.subdir, id: tour.id }
      expect(response.status).to(eq(401))
    end
  end

  describe 'POST #create' do
    it 'responds with 401 a tour when user is super' do
      user = create(:user, super: false)
      signed_cookie(user)
      post :create, params: { tenant: TourSet.first.subdir, tour: { title: 'A New Tour' } }
      expect(response).to(have_http_status(:unauthorized))
    end

    it 'creates a tour when user is super' do
      user = create(:user, super: true)
      signed_cookie(user)
      post :create, params: { tenant: TourSet.first.subdir, tour: { title: 'A New Tour' } }
      expect(response).to(have_http_status(:created))
    end

    it 'creates a tour when user is tour set admin' do
      tour_set = TourSet.last
      user = create(:user, super: false, tour_sets: [tour_set])
      signed_cookie(user)
      post :create, params: { tenant: tour_set.subdir, tour: { title: 'A New Tour' } }
      expect(response).to(have_http_status(:created))
    end

    it 'creates a tour when user is can create tours' do
      tour_set = TourSet.first
      user = create(:user, super: false)
      create(:tour_set_admin, user:, tour_set:, role: Role.find_by(title: 'Tour Creator'))
      signed_cookie(user)
      post :create, params: { tenant: TourSet.first.subdir, tour: { title: 'A New Tour' } }
      expect(response).to(have_http_status(:created))
      Apartment::Tenant.switch!(tour_set.subdir)
      expect(user.tours).to(include(Tour.find(v4_json[:id])))
    end

    it 'returns 401 when user is not tour creator for current tenant' do
      tour_set = TourSet.first
      user = create(:user, super: false)
      create(:tour_set_admin, user:, tour_set:, role: Role.find_by(title: 'Tour Creator'))
      signed_cookie(user)
      post :create, params: { tenant: TourSet.last.subdir, tour: { title: 'A New Tour' } }
      expect(response).to(have_http_status(:unauthorized))
    end
  end

  describe 'PATCH #update' do
    let(:tour) do
      Apartment::Tenant.switch!(tour_set.subdir)
      create(:tour_with_stops, published: false, stops_count: 3)
    end

    def patch_tour(document)
      patch(:update, params: { tenant: tour_set.subdir, id: tour.id, tour: document }, as: :json)
    end

    it 'returns 401 when unauthenticated' do
      patch_tour({ title: 'Nope' })
      expect(response.status).to(eq(401))
    end

    it 'returns 401 for a user who is not an author of the tour' do
      signed_cookie(create(:user, super: false))
      patch_tour({ title: 'Nope' })
      expect(response.status).to(eq(401))
      expect(tour.reload.title).not_to(eq('Nope'))
    end

    it 'allows an author of the tour' do
      user = create(:user, super: false)
      Apartment::Tenant.switch!(tour_set.subdir)
      user.tours << tour
      signed_cookie(user)
      patch_tour({ title: 'By author' })
      expect(response.status).to(eq(200))
    end

    it 'returns 404 for a missing tour' do
      signed_cookie(create(:user, super: true))
      patch :update, params: { tenant: tour_set.subdir, id: 0, tour: { title: 'x' } }, as: :json
      expect(response.status).to(eq(404))
    end

    it 'saves the document and responds with the tour built from the database' do
      signed_cookie(create(:user, super: true))
      Apartment::Tenant.switch!(tour_set.subdir)
      stops = tour.tour_stops.order(:position).map { |ts| { relation_id: ts.id, id: ts.stop_id } }
      reordered = stops.reverse.each_with_index.map { |entry, i| entry.merge(position: i + 1) }
      patch_tour({ title: 'Saved', stops: reordered })
      expect(response.status).to(eq(200))
      expect(v4_json[:title]).to(eq('Saved'))
      expect(v4_json[:stops].map { |s| s[:relation_id] }).to(eq(stops.reverse.map { |s| s[:relation_id] }))
    end

    it 'returns 422 with field paths for invalid documents' do
      signed_cookie(create(:user, super: true))
      patch_tour({ title: '' })
      expect(response.status).to(eq(422))
      expect(v4_json[:errors].first[:path]).to(eq('tour.title'))
    end

    it 'shows a tour straight from the database, without waiting for the index' do
      signed_cookie(create(:user, super: true))
      Apartment::Tenant.switch!(tour_set.subdir)
      fresh = create(:tour, published: false, title: 'Not indexed yet')
      get :show, params: { tenant: tour_set.subdir, id: fresh.id }
      expect(response.status).to(eq(200))
      expect(v4_json[:title]).to(eq('Not indexed yet'))
      expect(v4_json[:stops]).to(eq([]))
    end
  end

  describe 'GET #open_geographies' do
    let(:tour) { create(:tour, open_geographies_endpoint: 'http://og.ecds.io') }

    it 'returns 401 for a user who cannot edit the tour' do
      signed_cookie(create(:user, super: false))
      get :open_geographies, params: { tenant: Apartment::Tenant.current, id: tour.id }
      expect(response.status).to(eq(401))
    end

    it 'returns 404 for an unknown tour' do
      signed_cookie(create(:user, super: true))
      get :open_geographies, params: { tenant: Apartment::Tenant.current, id: 0 }
      expect(response.status).to(eq(404))
    end

    it 'previews the stops from Open Geographies, even for an unpublished tour' do
      signed_cookie(create(:user, super: true))
      tour.update!(published: false)
      get :open_geographies, params: { tenant: Apartment::Tenant.current, id: tour.id }
      expect(response.status).to(eq(200))
      body = JSON.parse(response.body)
      expect(body['stop_count']).to(eq(4))
      expect(body['version']).to(eq('v1'))
      expect(body['problems']).to(be_an(Array))
    end

    it 'checks a URL before it is saved to the tour' do
      signed_cookie(create(:user, super: true))
      tour.update!(open_geographies_endpoint: nil)
      get :open_geographies, params: { tenant: Apartment::Tenant.current, id: tour.id, url: 'http://og.ecds.io' }
      expect(response.status).to(eq(200))
      expect(JSON.parse(response.body)['stop_count']).to(eq(4))
      expect(tour.reload.open_geographies_endpoint).to(be_nil)
    end

    it 'refuses to check a URL on a host that is not allowed' do
      signed_cookie(create(:user, super: true))
      get :open_geographies, params: { tenant: Apartment::Tenant.current, id: tour.id, url: 'http://internal.test/admin' }
      expect(response.status).to(eq(422))
      expect(JSON.parse(response.body)['error']).to(eq("internal.test isn't an allowed Open Geographies host."))
    end

    it 'explains why a preview could not be made' do
      signed_cookie(create(:user, super: true))
      tour.update!(open_geographies_endpoint: nil)
      get :open_geographies, params: { tenant: Apartment::Tenant.current, id: tour.id }
      expect(response.status).to(eq(422))
      expect(JSON.parse(response.body)['error']).to(match(/No Open Geographies URL/))
    end
  end
end
