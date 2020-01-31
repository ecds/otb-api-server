# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V3::StopMedia', type: :request do
  let!(:stop) { create_list(:stop_with_media, 1) }
  let!(:medium) { create(:medium) }
  let!(:new_medium) { create(:medium) }
  let!(:user) { create(:user) }
  let!(:login) { create(:login, user: user) }
  let(:headers) { { Authorization: "Bearer #{login.oauth2_token}" } }

  describe 'GET /stop-media' do
    context 'gets all stop media' do
      before {
        get "/#{Apartment::Tenant.current}/stop-media"
      }

      it 'returns all stop media' do
        expect(response).to have_http_status(200)
        expect(json.size).to eq(StopMedium.count)
      end
    end

    context 'get stop medium with query parameters' do
      before {
        Stop.first.media << Medium.first
        get "/#{Apartment::Tenant.current}/stop-media?stop_id=#{Stop.first.id}&medium_id=#{Medium.first.id}"
      }

      it 'returns specific stop' do
        expect(response).to have_http_status(200)
        expect(relationships['stop']['data']['id']).to eq(Stop.first.id.to_s)
        expect(relationships['medium']['data']['id']).to eq(Medium.first.id.to_s)
      end
    end
  end

  describe 'GET /stop-media/<id>' do
    context 'it gets a specific stop medium by id' do
      before {
        get "/#{Apartment::Tenant.current}/stop-media/#{StopMedium.last.id}"
      }

      it 'returns specific stop-medium' do
        expect(json['id']).to eq(StopMedium.last.id.to_s)
      end
    end
  end

  describe 'POST /stop-media' do
    let(:valid_attributes) do
      factory_to_json_api(FactoryBot.build(:stop_medium, stop: stop.first, medium: medium, position: 4))
    end

    context 'add media to stop with specific position' do

      before { post "/#{Apartment::Tenant.current}/stop-media", params: valid_attributes, headers: headers }

      it 'created with specific position' do
        expect(response).to have_http_status(201)
        expect(attributes['position']).to eq(4)
      end
    end

    context 'add media to stop get default position at end' do
      let(:valid_attributes) do
        factory_to_json_api(FactoryBot.build(:stop_medium, stop: stop.first, medium: new_medium))
      end

      before { post "/#{Apartment::Tenant.current}/stop-media", params: valid_attributes, headers: headers }

      it 'created with default position at end' do
        expect(response).to have_http_status(201)
        expect(attributes['position']).to eq(6)
      end
    end

    context 'add medium to stop with invalid params' do
      before {
        post "/#{Apartment::Tenant.current}/stop-media", params: {}, headers: headers
      }

      it 'is unprocessable' do
        expect(response).to have_http_status(422)
      end
    end

    context 'add medium unauthenticated' do
      before {
        post "/#{Apartment::Tenant.current}/stop-media", params: valid_attributes
      }

      it 'returns 401' do
        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'PUT /stop-media' do
    let(:valid_attributes) do
      factory_to_json_api(FactoryBot.build(:stop_medium, stop: stop.first, medium: medium))
    end

    context 'update stop medium' do

      before { put "/#{Apartment::Tenant.current}/stop-media/#{StopMedium.first.id}", params: valid_attributes, headers: headers }

      it 'created with specific position' do
        expect(response).to have_http_status(200)
      end
    end

    context 'update medium to stop with invalid params' do
      before {
        valid_attributes[:data][:attributes]['stop_id'] = nil
        valid_attributes[:data][:attributes]['medium_id'] = nil
        put "/#{Apartment::Tenant.current}/stop-media/#{StopMedium.last.id}", params: valid_attributes, headers: headers
      }

      it 'is unprocessable' do
        expect(response).to have_http_status(422)
      end
    end

    context 'update medium unauthenticated' do
      before {
        put "/#{Apartment::Tenant.current}/stop-media/#{StopMedium.first.id}", params: valid_attributes
      }

      it 'returns 401' do
        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'DELETE /stop-media/<id>' do
    let!(:new_stop) { create_list(:stop_with_media, 1) }
    let(:medium_id) { new_stop.last.media.first.id }
    let(:stop_medium_id) { StopMedium.find_by(stop: new_stop.last).id }

    context 'delete stop medium' do
      before {
        delete "/#{Apartment::Tenant.current}/stop-media/#{stop_medium_id}", headers: headers
      }
  
      it 'deletes stop medium' do
        expect(response).to have_http_status(204)
        expect { Medium.find(medium_id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'delete stop medium unauthenticated' do
      before {
        delete "/#{Apartment::Tenant.current}/stop-media/#{StopMedium.last.id}"
      }
  
      it 'deletes stop medium' do
        expect(response).to have_http_status(401)
      end
    end
  end
end
