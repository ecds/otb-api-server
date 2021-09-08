require 'rails_helper'

RSpec.describe V3::GeojsonToursController, type: :controller do

  describe 'GET #show' do
    it 'returns a geojosn representation of a tour when tour published' do
      tour = create(:tour, published: true, media: create_list(:medium, rand(1..3)), stops: create_list(:stop, rand(4..7)))
      tour.stops.each { |stop| stop.media << create_list(:medium, rand(1..3)) }
      get :show, params: { id: tour.to_param, tenant: Apartment::Tenant.current }
      geojson = JSON.parse(response.body).with_indifferent_access
      expect(geojson[:type]).to eq('FeatureCollection')
      expect(geojson[:features].count).to eq(tour.stops.count)
      expect(geojson[:features].first[:geometry][:coordinates]).to eq([tour.stops.first.lng.to_f, tour.stops.first.lat.to_f])
      expect(geojson[:features].last[:properties][:images].first[:caption]).to eq(tour.stops.last.media.first.caption)
    end

    it 'returns 401 when tour is unpublished' do
      tour = create(:tour, published: false)
      get :show, params: { id: tour.to_param, tenant: Apartment::Tenant.current }
      expect(response.status).to eq(401)
    end
  end

end
