# frozen_string_literal: true

require 'rails_helper'
require 'ecds_rails_auth_engine'

RSpec.describe 'V3::FlatPages', type: :request do
  let!(:theme) { create(:theme) }
  let!(:tours) { create_list(:tour_with_flat_pages, 1, theme: theme) }
  let!(:flat_page) { tours.first.flat_pages.first }
  let(:tour_id) { tours.first.id }

  context 'create tour with flat pages' do
    before { get "/#{Apartment::Tenant.current}/flat-pages" }

    it 'associates flat_page with tour' do
      expect(response).to have_http_status(200)
      expect(json.size).to eq(3)
    end
  end

  context 'flat page included in tours payload' do
    before {
      tour = create(:tour_with_flat_pages, theme: theme)
      tour.published = true
      tour.save
      get "/#{Apartment::Tenant.current}/tours?slug=#{tour.slug}"
    }
    
    it 'creates tour with existing flat page' do
      expect(included.select { |d| d['type'] == 'tour_flat_pages' }.length).to eq(3)
    end
  end

  context 'get specific flat page by id' do
    before { get "/#{Apartment::Tenant.current}/flat-pages/#{FlatPage.first.id}" }

    it 'returns requested flat page' do
      expect(response).to have_http_status(200)
      expect(attributes['title']).to eq(FlatPage.first.title)
    end
  end

  # valid payload
  let(:valid_attributes) do
    factory_to_json_api(FactoryBot.build(:flat_page))
  end
  
  describe 'POST /tenant/flat-pages' do

    context 'create page not authenticated' do
      before { post "/#{Apartment::Tenant.current}/flat-pages", params: valid_attributes }
      it 'returns status code 401' do
        expect(response).to have_http_status(401)
      end
    end

    context 'when created by tour set admin' do
      before { User.first.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current) }
      before { post "/#{Apartment::Tenant.current}/flat-pages", params: valid_attributes, headers: { Authorization: "Bearer #{User.first.login.oauth2_token}" } }
      it 'creates a tour' do
        expect(response).to have_http_status(201)
      end
    end
  end
    
  describe 'PUT /tenant/flat-pages/<id>' do
    context 'update page not authenticated' do
      before { put "/#{Apartment::Tenant.current}/flat-pages/#{FlatPage.first.id}", params: valid_attributes}
      it 'returns status code 401' do
        expect(response).to have_http_status(401)
      end
    end

    context 'when updated by tour set admin' do
      before { User.first.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current) }
      before { put "/#{Apartment::Tenant.current}/flat-pages/#{FlatPage.first.id}", params: valid_attributes, headers: { Authorization: "Bearer #{User.first.login.oauth2_token}" } }
      it 'creates a tour' do
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'DELETE /tenant/flat-pages/<id>' do
    context 'delete page not authenticated' do
      before { delete "/#{Apartment::Tenant.current}/flat-pages/#{FlatPage.first.id}", params: valid_attributes}
      it 'returns status code 401' do
        expect(response).to have_http_status(401)
      end
    end

    context 'when deletes by tour set admin' do
      before { User.first.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current) }
      before { delete "/#{Apartment::Tenant.current}/flat-pages/#{FlatPage.first.id}", params: valid_attributes, headers: { Authorization: "Bearer #{User.first.login.oauth2_token}" } }
      it 'creates a tour' do
        expect(response).to have_http_status(204)
      end
    end
  end
end
