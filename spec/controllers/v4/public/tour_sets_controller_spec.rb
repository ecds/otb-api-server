# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V4::Public::TourSetsController, type: :controller do
  before(:each) do
    create_list(:tour_set, Random.new.rand(2..4))
    TourSet.all.each do |ts|
      Apartment::Tenant.switch! ts.subdir
      create_list(:tour, Random.new.rand(2..4))
    end
    Apartment::Tenant.switch! TourSet.first.subdir
    Tour.all.each { |t| t.update(published: false) }
    Apartment::Tenant.switch! TourSet.last.subdir
    Tour.first.update(published: true)
    Apartment::Tenant.reset
    TourSet.reindex
    TourSet.reindex
  end

  describe 'GET #index' do
    it 'returns a 200 and only TourSets with published tours when unauthenticated' do
      published_tour_sets = TourSet.all.select(&:should_index?)
      get :index, params: { tenant: "public" }
      expect(v4_json.count).to eq(published_tour_sets.count)
      expect(TourSet.count).to be > published_tour_sets.count
      expect(response.status).to eq(200)
    end

    it 'returns a 200 and only TourSets with published and authenticated user is admin' do
      Apartment::Tenant.switch! TourSet.second.subdir
      Tour.all.each { |t| t.update(published: false) }
      Apartment::Tenant.reset
      published_tour_sets = TourSet.all.select(&:should_index?)
      user = create(:user, super: false)
      signed_cookie(user)
      user.tour_sets << TourSet.second
      get :index, params: { tenant: "public" }
      expect(v4_json.count).to eq(published_tour_sets.count + 1)
      expect(v4_json.map { |ts| ts[:subdir] }).to include(TourSet.second.subdir)
      expect(TourSet.count).to be > published_tour_sets.count
      expect(response.status).to eq(200)
    end

    it 'returns a 200 and all TourSets when authenticated as super' do
      Apartment::Tenant.switch! TourSet.second.subdir
      Tour.all.each { |t| t.update(published: false) }
      Apartment::Tenant.reset
      published_tour_sets = TourSet.all.select(&:should_index?)
      user = create(:user, super: true)
      signed_cookie(user)
      get :index, params: { tenant: "public" }
      expect(v4_json.count).to eq(TourSet.count)
      expect(TourSet.count).to be > published_tour_sets.count
      expect(response.status).to eq(200)
    end
  end
end
