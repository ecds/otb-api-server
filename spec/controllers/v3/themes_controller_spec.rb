# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V3::ThemesController, type: :controller do

  before(:each) { create_list(:theme, rand(3..6)) }

  describe 'GET #index' do
    it 'returns a success response' do
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(response.status).to eq(200)
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      get :show, params: { id: Theme.last.to_param, tenant: Apartment::Tenant.current }
      expect(response.status).to eq(200)
    end
  end

  describe 'POST #create' do
    it 'returns 405' do
      post :create, params: { tenant: Apartment::Tenant.current, data: { type: 'theme', attributes: {} } }
      expect(response.status).to eq(405)
    end
  end

  describe 'PUT #update' do
    it 'renders a JSON response with errors for the theme' do
      put :update, params: { id: Theme.first.to_param, tenant: Apartment::Tenant.current, data: { type: 'theme', attributes: {} } }
      expect(response.status).to eq(405)
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested theme' do
      delete :destroy, params: { id: Theme.first.to_param, tenant: Apartment::Tenant.current }
      expect(response.status).to eq(405)
    end
  end

end
