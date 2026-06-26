# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(V4::Public::MediaController, type: :controller) do
  let(:tour_set) { create(:tour_set) }

  before { Apartment::Tenant.switch!(tour_set.subdir) }

  describe 'GET #show' do
    it 'returns 404 when key does not exist' do
      get :show, params: { tenant: tour_set.subdir, key: 'nonexistent' }
      expect(response).to(have_http_status(:not_found))
    end

    it 'redirects to blob url for a known key' do
      medium = create(:medium)
      get :show, params: { tenant: tour_set.subdir, key: medium.file.blob.key }
      expect(response).to(have_http_status(:redirect))
    end

    it 'redirects to variant url when variant param is given' do
      medium = create(:medium)
      get :show, params: { tenant: tour_set.subdir, key: medium.file.blob.key, variant: 'desktop' }
      expect(response).to(have_http_status(:redirect))
    end
  end
end
