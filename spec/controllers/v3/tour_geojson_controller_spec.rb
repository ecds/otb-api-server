require 'rails_helper'

RSpec.describe V3::GeojsonToursController, type: :controller do

  describe 'GET #show' do
    it 'returns a geojosn representation of a tour when tour published' do
      tour = create(:tour, published: true, media: create_list(:medium, rand(1..3)), stops: create_list(:stop, rand(4..7)))
      tour.stops.each { |stop| stop.media << create_list(:medium, rand(1..3)) }
      get :show, params: { id: tour.to_param, tenant: Apartment::Tenant.current }
      geojson = JSON.parse(response.body).with_indifferent_access
      first_stop = Stop.find_by(title: geojson[:features].first[:properties][:title])
      expect(geojson[:type]).to eq('FeatureCollection')
      expect(geojson[:features].count).to eq(tour.stops.count)
      expect(geojson[:features].first[:geometry][:coordinates]).to eq([first_stop.lng.to_f, first_stop.lat.to_f])
      expect(first_stop.media.map(&:caption)).to include geojson[:features].first[:properties][:images].first[:caption]
    end

    # TODO: Renable after OpenWorld stuff
    # it 'returns 401 when tour is unpublished' do
    #   tour = create(:tour, published: false)
    #   get :show, params: { id: tour.to_param, tenant: Apartment::Tenant.current }
    #   expect(response.status).to eq(401)
    # end
  end

end
