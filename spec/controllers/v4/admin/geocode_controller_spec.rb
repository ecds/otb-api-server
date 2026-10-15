# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(V4::Admin::GeocodeController, type: :controller) do
  let(:result) { { lat: 33.7, lng: -84.3, address: '315 Chester Avenue Southeast, Atlanta, GA 30316', name: nil } }

  def sign_in_super
    signed_cookie(create(:user, super: true))
  end

  it 'returns 401 when unauthenticated' do
    get :search, params: { tenant: Apartment::Tenant.current, q: 'Atlanta' }
    expect(response.status).to(eq(401))
  end

  it 'returns 401 for a signed-in user without access to the site' do
    signed_cookie(create(:user, super: false))
    get :search, params: { tenant: Apartment::Tenant.current, q: 'Atlanta' }
    expect(response.status).to(eq(401))
  end

  it 'searches for an address' do
    sign_in_super
    allow(AddressGeocoder).to(receive(:search).with('315 Chester Ave').and_return(result))
    get :search, params: { tenant: Apartment::Tenant.current, q: '315 Chester Ave' }
    expect(response.status).to(eq(200))
    expect(response.parsed_body['address']).to(eq(result[:address]))
  end

  it 'looks up the address at a point' do
    sign_in_super
    allow(AddressGeocoder).to(receive(:reverse).with('33.7', '-84.3').and_return(result))
    get :reverse, params: { tenant: Apartment::Tenant.current, lat: '33.7', lng: '-84.3' }
    expect(response.status).to(eq(200))
    expect(response.parsed_body['lat']).to(eq(33.7))
  end

  it 'returns 404 when nothing is found' do
    sign_in_super
    allow(AddressGeocoder).to(receive(:search).and_return(nil))
    get :search, params: { tenant: Apartment::Tenant.current, q: 'nowhere' }
    expect(response.status).to(eq(404))
    expect(response.parsed_body['error']).to(be_present)
  end
end
