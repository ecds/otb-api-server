# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V4::Public::ToursController, type: :controller do
  before(:each) { Tour.reindex }

  describe 'GET #index' do
    it 'returns a 200 response and empty tour when none found' do
      StopSlug.all.each { |t| t.delete }
      Stop.all.each { |t| t.delete }
      Tour.all.each { |t| t.delete }
      Tour.reindex
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(v4_json).to be_empty
      expect(response.status).to eq(200)
    end

    it 'returns a 200 response' do
      tour = create(:tour)
      Tour.reindex
      get :index, params: { tenant: tour.tenant }
      expect(response.status).to eq(200)
      expect(v4_json.count).to eq(Tour.published.count)
    end

    it 'returns all Tour objects when requested by tenant admin' do
      create_list(:tour, rand(4..5))
      user = create(:user, super: false)
      user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
      signed_cookie(user)
      Tour.reindex
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(v4_json.count).to eq(Tour.count)
    end

    it 'returns only tours where requester is an author' do
      Tour.all.each { |tour| tour.update(published: false) }
      Tour.first.update(published: true)
      new_tours = create_list(:tour, rand(4..6), published: false)
      user = create(:user, super: false)
      user.tour_sets = []
      user.tours << [ Tour.published.first, new_tours.first, new_tours.last ]
      Tour.reindex
      signed_cookie(user)
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(v4_json.count).to be < Tour.count
      expect(v4_json.count).to eq([ *user.tours, *Tour.published ].uniq.count)
    end
  end

  describe 'GET "#show' do
    it 'returns a 404 response when tour is not published' do
      tour = create(:tour)
      tour.update(published: false)
      Tour.reindex
      get :show, params: { tenant: tour.tenant, slug: tour.slug }
      expect(response.status).to eq(404)
      expect(v4_json[:errors].first).to eq("Not found")
    end

    it 'returns a 200 response when request is authenticated by tenant admin and tour is unpublished' do
      tour = create(:tour, published: false)
      tour.update(published: false)
      user = create(:user)
      user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
      signed_cookie(user)
      Tour.reindex
      get :show, params: { tenant: tour.tenant, slug: tour.slug }
      expect(response.status).to eq(200)
      expect(v4_json[:title]).to eq(tour.title)
    end

    it 'returns a 200 response when request is authenticated by tour author and tour is unpublished' do
      tour = create(:tour, published: false)
      tour.update(published: false)
      user = create(:user)
      user.tour_sets = []
      user.tours << tour
      signed_cookie(user)
      Tour.reindex
      get :show, params: { tenant: tour.tenant, slug: tour.slug }
      expect(response.status).to eq(200)
      expect(v4_json[:title]).to eq(tour.title)
    end

    it 'returns a 200 response when requested by slug' do
      tour = create(:tour)
      tour.update(published: true)
      Tour.reindex
      get :show, params: { tenant: tour.tenant, slug: tour.slug }
      expect(response.status).to eq(200)
      expect(v4_json[:title]).to eq(tour.title)
    end

    it "returns tour with multiple slugs" do
      tour = create(:tour, published: true)
      original_title = tour.title
      tour.update(title: Faker::Movies::HitchhikersGuideToTheGalaxy.location)
      new_title = tour.title
      Tour.reindex
      expect(original_title).not_to eq(new_title)
      expect(tour.slugs.count).to eq(2)
      get :show, params: { tenant: Apartment::Tenant.current, slug: tour.slugs.first.slug }
      expect(response.status).to eq(200)
      expect(v4_json[:title]).to eq(tour.title)
      expect(v4_json[:slug]).not_to eq(tour.slugs.first.slug)
    end
  end
end
