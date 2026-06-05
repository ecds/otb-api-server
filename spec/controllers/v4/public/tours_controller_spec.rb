# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(V4::Public::ToursController, type: :controller) do
  let(:tour_set) { create(:tour_set) }

  def clean_reindex
    begin
      Tour.search_index.delete
    rescue StandardError
      nil
    end
    Tour.reindex
  end

  before do
    Apartment::Tenant.switch!(tour_set.subdir)
    clean_reindex
  end

  describe 'GET #index' do
    it 'returns 404 when no tours exist' do
      clean_reindex
      get :index, params: { tenant: tour_set.subdir }
      expect(response.status).to(eq(404))
    end

    it 'returns 200 and only published tours when unauthenticated' do
      create(:tour_with_stops, published: true)
      create(:tour, published: false)
      clean_reindex
      get :index, params: { tenant: tour_set.subdir }
      expect(response.status).to(eq(200))
      expect(v4_json[:tours].count).to(eq(Tour.published.count))
    end

    it 'returns all tours when requested by tenant admin' do
      create_list(:tour, 3, published: false)
      user = create(:user, super: false)
      user.tour_sets << tour_set
      signed_cookie(user)
      clean_reindex
      get :index, params: { tenant: tour_set.subdir }
      expect(v4_json[:tours].count).to(eq(Tour.count))
    end

    it 'returns only published tours plus authored tours for a non-admin user' do
      published_tour = create(:tour, published: true)
      authored_unpublished = create_list(:tour, 3, published: false)
      other_unpublished = create(:tour, published: false)
      user = create(:user, super: false, tour_sets: [])
      user.tours << [published_tour, authored_unpublished.first, authored_unpublished.last]
      signed_cookie(user)
      clean_reindex
      get :index, params: { tenant: tour_set.subdir }
      expect(v4_json[:tours].count).to(be < Tour.count)
      expect(v4_json[:tours].count).to(eq([*user.tours, *Tour.published].uniq.count))
      expect(v4_json[:tours].map { |t| t[:id] }).not_to(include(other_unpublished.id))
    end
  end

  describe 'GET #show' do
    it 'returns 404 when tour is not published' do
      tour = create(:tour, published: false)
      clean_reindex
      get :show, params: { tenant: tour_set.subdir, slug: tour.slug }
      expect(response.status).to(eq(404))
      expect(v4_json[:errors].first).to(eq('Not found'))
    end

    it 'returns 200 when requested by tenant admin and tour is unpublished' do
      tour = create(:tour, published: false)
      user = create(:user)
      user.tour_sets << tour_set
      signed_cookie(user)
      clean_reindex
      get :show, params: { tenant: tour_set.subdir, slug: tour.slug }
      expect(response.status).to(eq(200))
      expect(v4_json[:tour][:title]).to(eq(tour.title))
    end

    it 'returns 200 when requested by tour author and tour is unpublished' do
      tour = create(:tour, published: false)
      user = create(:user, tour_sets: [])
      user.tours << tour
      signed_cookie(user)
      clean_reindex
      get :show, params: { tenant: tour_set.subdir, slug: tour.slug }
      expect(response.status).to(eq(200))
      expect(v4_json[:tour][:title]).to(eq(tour.title))
    end

    it 'returns 200 when requested by slug' do
      tour = create(:tour, published: true)
      clean_reindex
      get :show, params: { tenant: tour_set.subdir, slug: tour.slug }
      expect(response.status).to(eq(200))
      expect(v4_json[:tour][:title]).to(eq(tour.title))
    end

    it 'returns tour when requested by an old slug after title change' do
      tour = create(:tour, published: true)
      original_slug = tour.slugs.first.slug
      tour.update(title: Faker::Movies::HitchhikersGuideToTheGalaxy.location)
      clean_reindex
      expect(tour.slugs.count).to(eq(2))
      get :show, params: { tenant: tour_set.subdir, slug: original_slug }
      expect(response.status).to(eq(200))
      expect(v4_json[:tour][:title]).to(eq(tour.title))
      expect(v4_json[:tour][:slug]).not_to(eq(original_slug))
    end

    it 'returns stops from an Open Geographies endpoint' do
      tour = create(:tour, published: true, open_geographies: true, open_geographies_endpoint: 'http://og.ecds.io')
      clean_reindex
      get :show, params: { tenant: tour_set.subdir, slug: tour.slugs.first.slug }
      expect(v4_json[:tour][:stops]).to(eq(['Open Geographies']))
      expect(v4_json[:tour][:stop_count]).to(eq(1))
      expect(v4_json[:tour][:bounds]).to(eq({
        east: -83.8150232,
        west: -83.2818954,
        south: 32.6648851,
        north: 33.8113142,
      }))
      expect(v4_json[:tour][:title]).to(eq(tour.title))
    end
  end
end
