# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V3::ModesController, type: :controller do


  describe 'GET #index' do
    it 'returns a success response' do
      tour_set = create(:tour_set)
      get :index, params: { tenant: tour_set.subdir }
      expect(response.status).to eq(200)
      expect(json.count).to eq(4)
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      tour_set = create(:tour_set)
      Apartment::Tenant.switch! tour_set.subdir
      get :show, params: { id: Mode.first.to_param, tenant: tour_set.subdir }
      expect(response.status).to eq(200)
      expect(attributes[:title]).to eq(Mode.first.title)
    end
  end
end
