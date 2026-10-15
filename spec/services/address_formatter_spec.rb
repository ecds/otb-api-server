# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(AddressFormatter) do
  let(:atlanta) do
    {
      'office' => 'City of Atlanta Sanitation',
      'house_number' => '315',
      'road' => 'Chester Avenue Southeast',
      'suburb' => 'Reynoldstown',
      'city' => 'Atlanta',
      'county' => 'Fulton County',
      'state' => 'Georgia',
      'ISO3166-2-lvl4' => 'US-GA',
      'postcode' => '30316',
      'country' => 'United States',
      'country_code' => 'us',
    }
  end

  it 'formats a US street address with the state abbreviation' do
    expect(described_class.format(atlanta)).to(eq('315 Chester Avenue Southeast, Atlanta, GA 30316'))
  end

  it 'uses a town when there is no city' do
    parts = atlanta.except('city', 'suburb').merge('town' => 'Decatur')
    expect(described_class.format(parts)).to(eq('315 Chester Avenue Southeast, Decatur, GA 30316'))
  end

  it 'uses the full state name outside the US' do
    parts = { 'road' => 'High Street', 'city' => 'Oxford', 'state' => 'England', 'postcode' => 'OX1 4AA', 'country_code' => 'gb' }
    expect(described_class.format(parts)).to(eq('High Street, Oxford, England OX1 4AA'))
  end

  it 'falls back when there is no street' do
    parts = { 'leisure' => 'Piedmont Park', 'city' => 'Atlanta', 'country_code' => 'us' }
    expect(described_class.format(parts, 'Piedmont Park, Atlanta, Georgia')).to(eq('Piedmont Park, Atlanta, Georgia'))
  end

  it 'handles missing parts' do
    expect(described_class.format(nil, 'fallback')).to(eq('fallback'))
  end
end
