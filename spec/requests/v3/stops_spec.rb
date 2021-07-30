# frozen_string_literal: true

# app/requests/stops_spec.rb
require 'rails_helper'

RSpec.describe 'V3::Stops API' do
  # Initialize the test data
  let!(:user) { User.find_by(super: true) }

  # Test suite for GET /stops
  describe 'GET /stops' do
    context 'when stops exist' do

      before {
        user = create(:user)
        user.update(super: false)
        user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
        user.tours = []
        signed_cookie(user)
        cookies['auth'] = EcdsRailsAuthEngine::Login.find_by(user_id: user.id).token
        get "/#{Apartment::Tenant.current}/stops"
      }

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all tour stops' do
        expect(json.size).to eq(Stop.count)
      end
    end

    # context 'returns stops not associated with given tour' do
    #   before {
    #     get "/#{Apartment::Tenant.current}/stops?tour_id=#{Tour.last.id}"
    #   }

    #   it 'returns stops not part of given tour' do
    #     expect(json.size).to eq(Stop.not_in_tour(Tour.last.id).count)
    #   end
    # end

    context 'get stop by slug and tour' do
      before {
        Tour.first.update(published: true)
        Tour.first.stops << Stop.first
        get "/#{Apartment::Tenant.current}/tour-stops?slug=#{Stop.first.slug}&tour=#{Tour.first.id}"
      }

      it 'returns stop in tour with slug' do
        expect(json['id']).to eq(Stop.first.id.to_s)
        expect(relationships['tour']['data']['id']).to eq(Stop.first.tours.first.id.to_s)
      end
    end
  end

  # Test suite for GET /stops/:id
  describe 'GET /stops/:id' do
    before {
      Tour.first.update(published: true)
      Tour.first.stops << Stop.first
      get "/#{Apartment::Tenant.current}/stops/#{Stop.first.id}"
    }

    context 'when tour stop exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      # For now, access to stop is through /tour-stop?slug=XX&tour=Y
      # it 'returns the stop' do
      #   expect(json['id']).to eq(Stop.first.id.to_s)
      # end

      # it 'has a meta_description based on description truncated and sanitized' do
      #   expect(attributes['meta_description']).not_to include('<p>')
      # end
    end

    context 'when tour stop does not exist' do
      before { get "/#{Apartment::Tenant.current}/stops/0" }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Stop/)
      end
    end
  end

  describe 'GET /:tenant/tour-stops?slug=:stop_slug' do
    let!(:stop) { Stop.second }
    let!(:tour) { stop.tours.first }
    let!(:original_slug) { stop.slug }
    let!(:new_title) { "#{Faker::Movies::HitchhikersGuideToTheGalaxy.starship}" }

    context 'get stop after title change' do

      before {
        tour.update(published: true)
        stop.update(title: new_title)
      }
      before { get "/#{Apartment::Tenant.current}/tour-stops?slug=#{new_title.parameterize}&tour=#{tour.id}" }

      it 'gets same stop with new slug' do
        expect(response).to have_http_status(200)
        expect(attributes['slug']).to eq(new_title.parameterize)
        expect(json['id']).to eq(stop.id.to_s)
      end
    end

    # context 'get stop by old slug' do
    #   before { get "/#{Apartment::Tenant.current}/tour-stops?slug=#{original_slug}&tour=#{tour.id}" }

    #   it 'returns the stop by the original slug' do
    #     expect(response).to have_http_status(200)
    #     expect(attributes['slug']).to eq(new_title.parameterize)
    #     expect(json['id']).to eq(stop.id.to_s)
    #   end
    # end
  end

  # Test suite for POST /stops
  describe 'POST /stops' do
    let(:valid_attributes) do
      factory_to_json_api(FactoryBot.build(:stop, title: 'Players Ball'))
    end

    context 'when request attributes are valid' do
      before {
        User.first.update_attribute(:super, true)
        cookies['auth'] = EcdsRailsAuthEngine::Login.find_by(user_id: User.first.id).token
        post "/#{Apartment::Tenant.current}/stops", params: valid_attributes
      }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    # context 'when an invalid request' do
    #   before { post "/#{Apartment::Tenant.current}/stops", params: {}, headers: { Authorization: "Bearer #{User.second.login.oauth2_token}" } }

    #   it 'returns status code 422' do
    #     expect(response).to have_http_status(422)
    #   end

    #   # it 'returns a failure message' do
    #   #   expect(response.body).to match(/\{\"title\"\:\[\"can\'t be blank\"\]\}/)
    #   # end
    # end
  end

  # Test suite for PUT /stops/:id
  describe 'PUT /stops/:id' do
    let(:valid_attributes) do
      factory_to_json_api(FactoryBot.build(:stop, title: '3 Stacks'))
    end

    before {
      cookies['auth'] = EcdsRailsAuthEngine::Login.find_by(user_id: user.id).token
      put "/#{Apartment::Tenant.current}/stops/#{Stop.second.id}", params: valid_attributes
    }

    context 'when stop exists' do
      it 'returns status code 204' do
        expect(response).to have_http_status(200)
      end

      it 'updates the stop' do
        updated_stop = Stop.second
        expect(updated_stop.title).to match(/3 Stacks/)
      end
    end

    context 'when the stop does not exist' do
      before {
        cookies['auth'] = EcdsRailsAuthEngine::Login.find_by(user_id: user.id).token
        put "/#{Apartment::Tenant.current}/stops/0", params: valid_attributes
      }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Stop/)
      end
    end
  end

  # Test suite for DELETE /stops/:id
  describe 'DELETE /stops/:id' do
    before {
      cookies['auth'] = EcdsRailsAuthEngine::Login.find_by(user_id: user.id).token
      delete "/#{Apartment::Tenant.current}/stops/#{Stop.last.id}"
    }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
