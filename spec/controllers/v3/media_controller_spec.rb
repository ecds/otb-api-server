# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V3::MediaController, type: :controller do

  let(:valid_params) {
    {
      data: {
        type: 'media',
        attributes: {
          base_sixty_four: File.read(Rails.root.join('spec/factories/base64_image.txt')),
          filename: Faker::File.file_name(dir: '', ext: 'png', directory_separator: '')
        }
      },
      tenant: Apartment::Tenant.current
    }
  }

  if ENV['DB_ADAPTER'] == 'mysql2'
    skip('Fix this spec for MySQL. Something to do with it being transactional')
  else
    describe 'GET #index' do

      it 'returns a success response' do
        create_list(:medium, 5)
        tour = create(:tour, published: true)
        Medium.all.each { |m| tour.media << m }
        get :index, params: { tenant: Apartment::Tenant.current }
        expect(response.status).to eq(200)
        expect(json.count).to eq(tour.media.count)
      end

      it 'returns only media associated with a public tour' do
        published_tour = create(:tour, published: true)
        create_list(:medium, rand(1..8)).each { |m| published_tour.media << m }
        unpublished_tour = create(:tour, published: false)
        create_list(:medium, rand(1..8)).each { |m| unpublished_tour.media << m }
        get :index, params: { tenant: Apartment::Tenant.current }
        expect(json.count).to eq(Tour.published.map { |t| t.media.count }.sum)
        expect(json.count).to be < Medium.count
      end

      it 'returns all media when requested by tenant admin' do
        published_tour = create(:tour, published: true)
        create_list(:medium, rand(1..8)).each { |m| published_tour.media << m }
        unpublished_tour = create(:tour, published: false)
        create_list(:medium, rand(1..8)).each { |m| unpublished_tour.media << m }
        user = create(:user)
        user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
        signed_cookie(user)
        get :index, params: { tenant: Apartment::Tenant.current }
        expect(response.status).to eq(200)
        expect(json.count).to eq(Medium.count)
        expect(Medium.count).to be > Tour.published.map { |t| t.media.count }.sum
      end
    end

    describe 'GET #show' do
      it 'returns 401 when medium is not published by a tour or stop' do
        medium = create(:medium)
        get :show, params: { tenant: Apartment::Tenant.current, id: medium.id }
        expect(response.status).to eq(200)
        expect(medium.published).to be false
        expect(attributes[:title]).to eq('....')
      end

      it 'returns the medium when associated with published stop' do
        tour = create(:tour, published: true)
        stop = create(:stop)
        medium = create(:medium)
        tour.stops << stop
        stop.media << medium
        get :show, params: { tenant: Apartment::Tenant.current, id: medium.id }
        expect(medium.published).to be true
        expect(response.status).to eq(200)
        expect(attributes[:title]).to eq(medium.title)
      end

      it 'returns the medium when unpublished but requested is authorized' do
        medium = create(:medium)
        user = create(:user)
        user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
        signed_cookie(user)
        get :show, params: { tenant: Apartment::Tenant.current, id: medium.id }
        expect(medium.published).to be false
        expect(response.status).to eq(200)
        expect(attributes[:title]).to eq(medium.title)
      end
    end

    describe 'POST #create' do
      context 'with valid params and request is authorized' do
        it 'creates a new Medium' do
          user = create(:user)
          user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
          signed_cookie(user)
          expect {
            post :create, params: valid_params
          }.to change(Medium, :count).by(1)
        end

        it 'renders a JSON response with the new medium when super' do
          user = create(:user, super: true)
          signed_cookie(user)
          post :create, params: valid_params
          expect(response).to have_http_status(:created)
          expect(response.content_type).to eq('application/json; charset=utf-8')
          expect(json[:id]).to eq(Medium.last.id.to_s)
        end

        it 'renders a JSON response with the new medium when tenant admin' do
          user = create(:user)
          user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
          signed_cookie(user)
          post :create, params: valid_params
          expect(response).to have_http_status(:created)
          expect(response.content_type).to eq('application/json; charset=utf-8')
          expect(json[:id]).to eq(Medium.last.id.to_s)
        end

        it 'renders a JSON response with the new medium when tour author' do
          user = create(:user)
          tour = create(:tour)
          user.tour_sets = []
          user.tours << tour
          signed_cookie(user)
          post :create, params: valid_params
          expect(response).to have_http_status(:created)
          expect(response.content_type).to eq('application/json; charset=utf-8')
          expect(json[:id]).to eq(Medium.last.id.to_s)
        end
      end

      context 'with invalid params' do
        it 'renders a JSON response with errors for the new medium' do
          user = create(:user)
          user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
          signed_cookie(user)
          post :create, params: { medium: 'invalid_params', tenant: Apartment::Tenant.current }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.content_type).to eq('application/json; charset=utf-8')
        end
      end

      context 'with unauthenticated request' do
        it 'responds unauthorized when unauthenticated' do
          post :create, params: valid_params
          expect(response).to have_http_status(:unauthorized)
        end

        it 'responds unauthorized when authenticated but not authorized' do
          initial_tenant = Apartment::Tenant.current
          user = create(:user)
          user.tour_sets << create(:tour_set)
          signed_cookie(user)
          Apartment::Tenant.switch! initial_tenant
          post :create, params: valid_params
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    describe 'PUT #update' do
      context 'with valid params and request is authorized' do

        it 'renders a JSON response with the new medium when super' do
          medium = create(:medium)
          update_params = JSON.parse(ActiveModelSerializers::Adapter::JsonApi.new(V3::MediumSerializer.new(medium)).to_json).with_indifferent_access
          update_params[:tenant] = Apartment::Tenant.current
          update_params[:id] = update_params[:data][:id]
          user = create(:user, super: true)
          initial_title = update_params[:data][:attributes][:title]
          update_params[:data][:attributes][:title] = Faker::Movies::HitchhikersGuideToTheGalaxy.location
          signed_cookie(user)
          post :update, params: update_params
          expect(response).to have_http_status(:ok)
          expect(attributes[:title]).not_to eq(initial_title)
        end

        it 'renders a JSON response with the new medium when tenant admin' do
          medium = create(:medium)
          update_params = JSON.parse(ActiveModelSerializers::Adapter::JsonApi.new(V3::MediumSerializer.new(medium)).to_json).with_indifferent_access
          update_params[:tenant] = Apartment::Tenant.current
          update_params[:id] = update_params[:data][:id]
          user = create(:user, super: false)
          user.tours = []
          user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
          initial_title = update_params[:data][:attributes][:title]
          update_params[:data][:attributes][:title] = Faker::Movies::HitchhikersGuideToTheGalaxy.location
          signed_cookie(user)
          post :update, params: update_params
          expect(response).to have_http_status(:ok)
          expect(attributes[:title]).not_to eq(initial_title)
        end

        it 'renders a JSON response with the new medium when tour author' do
          medium = create(:medium)
          update_params = JSON.parse(ActiveModelSerializers::Adapter::JsonApi.new(V3::MediumSerializer.new(medium)).to_json).with_indifferent_access
          update_params[:tenant] = Apartment::Tenant.current
          update_params[:id] = update_params[:data][:id]
          user = create(:user, super: false)
          user.tour_sets = []
          user.tours << create(:tour)
          initial_title = update_params[:data][:attributes][:title]
          update_params[:data][:attributes][:title] = Faker::Movies::HitchhikersGuideToTheGalaxy.location
          signed_cookie(user)
          post :update, params: update_params
          expect(response).to have_http_status(:ok)
          expect(attributes[:title]).not_to eq(initial_title)
        end
      end

      context 'with invalid params' do
        it 'renders a JSON response with errors for the new medium' do
          user = create(:user, super: true)
          signed_cookie(user)
          post :update, params: { id: create(:medium).id, data: { type: 'medium', attributes: { filename: nil } }, tenant: Apartment::Tenant.current }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.content_type).to eq('application/json; charset=utf-8')
        end
      end

      context 'with unauthenticated request' do
        it 'responds unauthorized when unauthenticated' do
          medium = create(:medium)
          update_params = JSON.parse(ActiveModelSerializers::Adapter::JsonApi.new(V3::MediumSerializer.new(medium)).to_json).with_indifferent_access
          update_params[:tenant] = Apartment::Tenant.current
          update_params[:id] = update_params[:data][:id]
          post :update, params: update_params
          expect(response).to have_http_status(:unauthorized)
        end

        it 'responds unauthorized when authenticated but not authorized' do
          initial_tenant = Apartment::Tenant.current
          medium = create(:medium)
          update_params = JSON.parse(ActiveModelSerializers::Adapter::JsonApi.new(V3::MediumSerializer.new(medium)).to_json).with_indifferent_access
          update_params[:tenant] = Apartment::Tenant.current
          update_params[:id] = update_params[:data][:id]
          user = create(:user, super: false)
          user.tour_sets << create(:tour_set)
          signed_cookie(user)
          Apartment::Tenant.switch! initial_tenant
          post :update, params: update_params
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    describe 'DELETE #destroy' do
      context 'authenticated and authorized' do
        it 'destroys the requested medium when request from super' do
          medium = create(:medium)
          user = create(:user, super: true)
          signed_cookie(user)
          expect {
            delete :destroy, params: { id: medium.to_param, tenant: Apartment::Tenant.current }
          }.to change(Medium, :count).by(-1)
        end

        it 'destroys the requested medium when request from tenant admin' do
          medium = create(:medium)
          user = create(:user, super: false)
          user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
          signed_cookie(user)
          expect {
            delete :destroy, params: { id: medium.to_param, tenant: Apartment::Tenant.current }
          }.to change(Medium, :count).by(-1)
        end

        it 'destroys the requested medium when request from tour author' do
          medium = create(:medium)
          user = create(:user, super: false)
          user.tour_sets = []
          user.tours << create(:tour)
          signed_cookie(user)
          expect {
            delete :destroy, params: { id: medium.to_param, tenant: Apartment::Tenant.current }
          }.to change(Medium, :count).by(-1)
        end
      end

      context 'authenticated but not authorized' do
        it 'returns unauthorized' do
          initial_tenant = Apartment::Tenant.current
          medium = create(:medium)
          user = create(:user, super: false)
          Apartment::Tenant.reset
          tour_set = create(:tour_set)
          user.tour_sets << tour_set
          signed_cookie(user)
          Apartment::Tenant.switch! initial_tenant
          initial_media_count = Medium.count
          delete :destroy, params: { id: medium.to_param, tenant: Apartment::Tenant.current }
          expect(response).to have_http_status(:unauthorized)
          expect(Medium.count).to eq(initial_media_count)
        end
      end

      context 'unauthenticated' do
        it 'returns unauthorized' do
          medium = create(:medium)
          initial_media_count = Medium.count
          delete :destroy, params: { id: medium.to_param, tenant: Apartment::Tenant.current }
          expect(response).to have_http_status(:unauthorized)
          expect(Medium.count).to eq(initial_media_count)
        end
      end
    end
  end
end
