# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V3::Tours', type: :request do
  before {
    set = TourSet.find(TourSet.pluck(:id).sample).subdir
    Apartment::Tenant.switch! set
    Tour.first.update_attribute(:published, true)
  }

  describe 'GET /atlanta/tours unauthenticated' do
    before {
      get "/#{Apartment::Tenant.current}/tours"
    }

    it 'returns only published tours' do
      expect(json.size).to eq(Tour.published.count)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /atlanta/tours/:id
  describe 'GET /atlanta/tours/:id' do
    before { get "/#{Apartment::Tenant.current}/tours/#{Tour.published.last.id}" }

    context 'when the record exists' do
      it 'returns the tour' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(Tour.published.last.id.to_s)
      end

      it 'has five stops' do
        expect(relationships['tour_stops']['data'].size).to eq(Tour.published.last.tour_stops.length)
        expect(relationships['stops']['data'].size).to eq(Tour.published.last.stops.length)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns description without html tags and space between sentences' do
        expect(attributes['sanitized_description']).not_to include('<p>')
        expect(attributes['sanitized_description']).not_to match(/.*[A-z]\.[A-z].*/)
      end
    end

    context 'when the record does not exist' do
      before { get "/#{Apartment::Tenant.current}/tours/0" }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Tour/)
      end
    end
  end

  describe 'GET /:tenant/:tour_slug' do
    let!(:tour) { Tour.published.last }
    let!(:original_title) { tour.title }
    let!(:original_slug) { tour.slug }
    let!(:new_title) { Faker::TvShows::RickAndMorty.character }

    context 'get tour after title change' do
      before {
        tour.title = new_title
        tour.published = true
        tour.save
      }

      before { get "/#{Apartment::Tenant.current}/tours?slug=#{new_title.parameterize}" }

      it 'gets same tour with new slug' do
        expect(response).to have_http_status(200)
        expect(attributes['slug']).to eq(new_title.parameterize)
        expect(json['id']).to eq(tour.id.to_s)
      end
    end

    context 'get tour by old slug' do
      before {
        tour.title = original_title
        tour.published = true
        tour.save
        tour.title = new_title
        tour.save
      }
      before { get "/#{Apartment::Tenant.current}/tours?slug=#{original_slug}" }

      it 'returns the tour by the original slug' do
        expect(response).to have_http_status(200)
        expect(attributes['slug']).to eq(new_title.parameterize)
        expect(json['id']).to eq(tour.id.to_s)
      end
    end

    context 'get nothing if tour is unpublished and no user' do
      before {
        tour.published = false
        tour.save
        get "/#{Apartment::Tenant.current}/tours?slug=#{tour.slug}"
      }

      it 'returns nothing' do
        expect(response).to have_http_status(404)
      end
    end
  end

  # Test suite for POST /atlanta/tours
  describe 'POST /atlanta/tours' do
    # valid payload
    let(:valid_attributes) do
      factory_to_json_api(FactoryBot.build(:tour, title: 'Learn Elm', published: true))
    end
    before { Apartment::Tenant.switch! TourSet.find(TourSet.pluck(:id).sample).subdir }

    context 'when the post is valid and authenticated as non-tour set admin' do
      before {
        User.last.update_attribute(:super, false)
        User.last.update_attribute(:tour_sets, [])
        cookies['auth'] = EcdsRailsAuthEngine::Login.find_by(user_id: User.last.id).token
        post "/#{Apartment::Tenant.current}/tours", params: valid_attributes
      }

      it 'returns status code 401' do
        expect(response).to have_http_status(401)
      end
    end

    context 'when created by tour set admin' do
      before {
        User.first.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
        cookies['auth'] = EcdsRailsAuthEngine::Login.find_by(user_id: User.first.id).token
        post "/#{Apartment::Tenant.current}/tours", params: valid_attributes
      }
      it 'creates a tour' do
        expect(attributes['title']).to eq('Learn Elm')
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is is missing title' do
      let(:invalid_attributes) do
        hash_to_json_api('tours', invalid: 'Foobar')
      end
      before {
        # Tour.create!(published: true)
        User.first.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
        cookies['auth'] = EcdsRailsAuthEngine::Login.find_by(user_id: User.first.id).token
        post "/#{Apartment::Tenant.current}/tours", params: invalid_attributes
      }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'returns new tour titled `untitled`' do
        expect(attributes['title']).to eq('untitled')
      end
    end
  end

  # Test suite for PUT /atlanta/tours/:id
  describe 'PUT /<tenant>/tours/:id' do
    let(:valid_attributes) do
      factory_to_json_api(FactoryBot.build(:tour, title: 'Shopping'))
    end

    context 'when the record exists' do
      before {
        cookies['auth'] = EcdsRailsAuthEngine::Login.find_by(user_id: User.first.id).token
        put "/#{Apartment::Tenant.current}/tours/#{Tour.last.id}", params: valid_attributes
      }

      it 'updates the record' do
        expect(json).not_to be_empty
        expect(attributes['title']).to eq('Shopping')
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end

  # Test suite for DELETE /atlanta/tours/:id
  describe 'DELETE /atlanta/tours/:id' do
    before {
      Tour.create!
      User.first.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
      cookies['auth'] = EcdsRailsAuthEngine::Login.find_by(user_id: User.first.id).token
      delete "/#{Apartment::Tenant.current}/tours/#{Tour.last.id}"
    }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end

  describe 'Get /<tenant>/tours authenticated' do
    context 'tour set adim gets all the tours for that set' do
      before {
        User.last.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
        cookies['auth'] = EcdsRailsAuthEngine::Login.find_by(user_id: User.last.id).token
        get "/#{Apartment::Tenant.current}/tours"
      }

      it 'returns all the tours in the set' do
        expect(json.size).to eq(Tour.count)
      end
    end

    context 'get tours as tour author' do
      before {
        user = User.first
        login = EcdsRailsAuthEngine::Login.find_by(user_id: user.id)
        user.update(super: false, tour_sets: [], tours: [])
        # user.super = false
        # user.tour_sets = []
        # user.tours = []
        user.save
        user.tours << Tour.first
        Tour.all.each do |t|
          t.published = false
          t.save
        end
        cookies['auth'] = login.token
        get "/#{Apartment::Tenant.current}/tours"
      }

      it 'only returns tours user can edit' do
        expect(json.size).to eq(1)
        expect(json.size).not_to eq(Tour.count)
      end
    end
  end
end
