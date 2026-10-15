# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(AddressGeocoder) do
  let(:place) do
    {
      lat: '33.7444777',
      lon: '-84.3597633',
      name: 'City of Atlanta Sanitation',
      display_name: 'City of Atlanta Sanitation, 315, Chester Avenue Southeast, Atlanta, Georgia, 30316, United States',
      address: {
        house_number: '315',
        road: 'Chester Avenue Southeast',
        city: 'Atlanta',
        state: 'Georgia',
        'ISO3166-2-lvl4': 'US-GA',
        postcode: '30316',
        country_code: 'us',
      },
    }
  end
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }

  before do
    stub_const('AddressGeocoder::MIN_INTERVAL', 0)
    allow(Rails).to(receive(:cache).and_return(cache))
  end

  def stub_search(body)
    stub_request(:get, %r{nominatim\.openstreetmap\.org/search}).to_return(
      body: body.to_json, headers: { 'Content-Type' => 'application/json' },
    )
  end

  def stub_reverse(body)
    stub_request(:get, %r{nominatim\.openstreetmap\.org/reverse}).to_return(
      body: body.to_json, headers: { 'Content-Type' => 'application/json' },
    )
  end

  describe '.search' do
    it 'returns the location with a formatted address and place name' do
      stub_search([place])
      expect(described_class.search('315 Chester Ave Atlanta')).to(eq(
        lat: 33.7444777,
        lng: -84.3597633,
        address: '315 Chester Avenue Southeast, Atlanta, GA 30316',
        name: 'City of Atlanta Sanitation',
      ))
    end

    it 'identifies itself to Nominatim' do
      stub = stub_search([place]).with(headers: { 'User-Agent' => %r{OpenTourBuilder/} })
      described_class.search('315 Chester Ave Atlanta')
      expect(stub).to(have_been_requested)
    end

    it 'caches results by query' do
      stub = stub_search([place])
      described_class.search('315 Chester Ave Atlanta')
      described_class.search('  315 chester ave atlanta ')
      expect(stub).to(have_been_requested.once)
    end

    it 'returns nil, uncached, when nothing matches' do
      stub = stub_search([])
      expect(described_class.search('nowhere at all')).to(be_nil)
      described_class.search('nowhere at all')
      expect(stub).to(have_been_requested.twice)
    end

    it 'ignores a blank query' do
      expect(described_class.search('  ')).to(be_nil)
    end
  end

  describe '.reverse' do
    it 'looks up the address at a point' do
      stub_reverse(place)
      expect(described_class.reverse('33.74448', '-84.35976')[:address]).to(eq('315 Chester Avenue Southeast, Atlanta, GA 30316'))
    end

    it 'shares results for points within about a metre' do
      stub = stub_reverse(place)
      described_class.reverse(33.744481, -84.359761)
      described_class.reverse(33.744482, -84.359762)
      expect(stub).to(have_been_requested.once)
    end

    it 'rejects coordinates that are not on the map' do
      expect(described_class.reverse('abc', 10)).to(be_nil)
      expect(described_class.reverse(91, 10)).to(be_nil)
    end
  end
end
