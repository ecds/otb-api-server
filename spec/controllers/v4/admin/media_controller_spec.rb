# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(V4::Admin::MediaController, type: :controller) do
  describe 'GET #index' do
    it 'returns an empty array, not a JSON:API document, when there are no media' do
      signed_cookie(create(:user, super: true))
      get :index, params: { tenant: Apartment::Tenant.current, exclude: '0' }
      expect(JSON.parse(response.body)).to(be_a(Array))
    end

    it 'returns 401 when unauthenticated' do
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(response.status).to(eq(401))
    end

    it 'returns 200 and list of medium when authenticated as super' do
      user = create(:user, super: true)
      signed_cookie(user)
      create_list(:medium, 4)
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(response.status).to(eq(200))
      expect(v4_json.count).to(eq(Medium.count))
    end

    it 'returns 200 and list of medium when authenticated as site owner' do
      user = create(:user, super: false)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch!(tour_set.subdir)
      create_list(:medium, 3)
      user.tour_sets << tour_set
      signed_cookie(user)
      get :index, params: { tenant: tour_set.subdir }
      expect(response.status).to(eq(200))
      expect(v4_json.count).to(eq(Medium.count))
    end

    it 'returns 200 and list of medium when authenticated as tour author' do
      user = create(:user, super: false)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      create_list(:medium, 2)
      user.tours << tour
      signed_cookie(user)
      get :index, params: { tenant: tour_set.subdir }
      expect(response.status).to(eq(200))
      expect(v4_json.count).to(eq(Medium.count))
    end

    it 'returns 401 when authenticated as site owner but requesting medium for different site' do
      user = create(:user, super: false)
      tour_sets = create_list(:tour_set, 4)
      Apartment::Tenant.switch!(tour_sets.first.subdir)
      user.tour_sets << tour_sets.last
      signed_cookie(user)
      get :index, params: { tenant: tour_sets.first.subdir }
      expect(response.status).to(eq(401))
    end

    it 'returns 200 and paginated list of medium when authenticated as site owner' do
      user = create(:user, super: false)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch!(tour_set.subdir)
      create_list(:medium, 3)
      user.tour_sets << tour_set
      signed_cookie(user)
      get :index, params: { tenant: tour_set.subdir, page: 2, per: 1 }
      expect(response.status).to(eq(200))
      expect(v4_json.count).to(eq(1))
    end

    it 'returns 200 with specified media excluded' do
      user = create(:user, super: true)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch!(tour_set.subdir)
      media = create_list(:medium, 4)
      user.tour_sets << tour_set
      signed_cookie(user)
      get :index, params: { tenant: tour_set.subdir, exclude: "#{media.first.id}, #{media.second.id}" }
      expect(response.status).to(eq(200))
      expect(v4_json.count).to(eq(Medium.count - 2))
      expect(v4_json.map { |m| m[:id] }).not_to(include(media.first.id))
      expect(v4_json.map { |m| m[:id] }).not_to(include(media.second.id))
    end
  end

  describe 'GET #index filtered by tour' do
    let(:tour) { create(:tour) }
    let(:other_tour) { create(:tour) }
    let!(:on_tour) { create(:medium) }
    let!(:on_stop) { create(:medium) }
    let!(:elsewhere) { create(:medium) }

    before do
      signed_cookie(create(:user, super: true))
      create(:tour_medium, tour:, medium: on_tour)
      stop = create(:stop)
      create(:tour_stop, tour:, stop:)
      create(:stop_medium, stop:, medium: on_stop)
      create(:tour_medium, tour: other_tour, medium: elsewhere)
    end

    it 'returns media used by the tour or any of its stops' do
      get :index, params: { tenant: Apartment::Tenant.current, tour_id: tour.id }
      expect(v4_json.pluck(:id)).to(contain_exactly(on_tour.id, on_stop.id))
    end

    it 'lists each medium once even when the tour and a stop both use it' do
      stop = create(:stop)
      create(:tour_stop, tour:, stop:)
      create(:stop_medium, stop:, medium: on_tour)
      get :index, params: { tenant: Apartment::Tenant.current, tour_id: tour.id }
      expect(v4_json.pluck(:id).count(on_tour.id)).to(eq(1))
    end

    it 'paginates only the matching media' do
      get :index, params: { tenant: Apartment::Tenant.current, tour_id: tour.id, page: 1, per: 1 }
      expect(v4_json.count).to(eq(1))
      expect(response.headers['Link']).to(include('rel="last"'))
      expect(response.headers['Link']).to(include('page=2'))
      expect(response.headers['Link']).not_to(include('page=3'))
    end

    it 'says which tours use each medium' do
      get :index, params: { tenant: Apartment::Tenant.current, tour_id: tour.id }
      by_id = v4_json.index_by { |medium| medium[:id] }
      expect(by_id[on_stop.id][:appears_in]).to(eq([{ id: tour.id, title: tour.title }]))
    end

    it 'loads appears_in without a query per medium' do
      # Same shape for every medium (on a tour and on a stop), so the only
      # difference between the two pages is how many media they hold.
      6.times do
        medium = create(:medium)
        create(:tour_medium, tour: other_tour, medium:)
        stop = create(:stop)
        create(:tour_stop, tour: other_tour, stop:)
        create(:stop_medium, stop:, medium:)
      end
      queries = lambda { |per|
        count = 0
        counter = ->(*, payload) { count += 1 unless payload[:name] == 'SCHEMA' }
        ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') do
          get(:index, params: { tenant: Apartment::Tenant.current, page: 1, per: })
        end
        count
      }
      expect(queries.call(6)).to(eq(queries.call(3)))
    end

    it 'still applies exclude' do
      get :index, params: { tenant: Apartment::Tenant.current, tour_id: tour.id, exclude: on_tour.id.to_s }
      expect(v4_json.pluck(:id)).to(eq([on_stop.id]))
    end

    it 'returns empty list when tour has no media' do
      tour = create(:tour, stops: [], media: [])
      get :index, params: { tenant: Apartment::Tenant.current, tour_id: tour.id }
      expect(v4_json).to(be_empty)
    end
  end
end
