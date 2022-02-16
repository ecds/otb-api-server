# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V3::TourSetsController, type: :controller do

  # This should return the minimal set of attributes required to create a valid
  # TourSet. As you add validations to TourSet, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
  }

  let(:invalid_attributes) {
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # TourSetsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe 'TourSetsController' do
    let(:valid_params) { { data: { type: 'tour_sets', attributes: { name: Faker::Music::Hiphop.artist } }, tenant: 'public' } }
    let(:invalid_params) { { data: { type: 'tour_sets', attributes: { name: nil } }, tenant: 'public' } }

    before(:each) do
      Apartment::Tenant.reset
      TourSet.all.each { |ts| ts.delete }
      create_list(:tour_set, rand(3..5))
    end

    describe 'GET #index' do
      it 'returns a success response but return no TourSet objects' do
        get :index, params: { tenant: 'public' }
        expect(response.status).to eq(200)
        expect(json.count).to eq(0)
      end

      it 'returns a success response and returns TourSet objects with tours that are published and have stops' do
        Apartment::Tenant.switch! TourSet.second.subdir
        tour = create(:tour, published: true)
        tour.stops << create(:stop)
        get :index, params: { tenant: 'public' }
        expect(response.status).to eq(200)
        expect(json.count).to eq(1)
      end

      it 'returns a success response by subdir but returns no TourSet objects when no published tours and not authorized' do
        get :index, params: { tenant: 'public', subdir: TourSet.last.subdir }
        expect(response.status).to eq(200)
        expect(json.count).to eq(0)
      end

      it 'returns a success response by and TourSet object by subdir when tour set has a published tour and not authorized' do
        Apartment::Tenant.switch! TourSet.second.subdir
        tour = create(:tour, published: true)
        tour.stops << create(:stop)
        get :index, params: { tenant: 'public', subdir: TourSet.second.subdir }
        expect(response.status).to eq(200)
        expect(json.count).to eq(1)
      end

      it 'returns all TourSet objects when requested by super' do
        user = create(:user, super: true)
        signed_cookie(user)
        get :index, params: { tenant: 'public' }
        expect(response.status).to eq(200)
        expect(json.count).to eq(TourSet.count)
      end

      it 'returns TourSet objects when requested by admin' do
        user = create(:user, super: false)
        user.tour_sets << [TourSet.first, TourSet.last]

        # Make sure a set doesn't slip in because of published tours.
        [TourSet.first.subdir, TourSet.last.subdir].each do |ts|
          Apartment::Tenant.switch! ts
          Tour.all.update(published: false)
        end

        # Make a new set with published tour to make sure it's included.
        published_set = create(:tour_set)
        Apartment::Tenant.switch! published_set.subdir
        create(:tour, published: true, stops: create_list(:stop, 2))

        Apartment::Tenant.reset
        signed_cookie(user)
        get :index, params: { tenant: 'public' }
        expect(response.status).to eq(200)
        expect(json.count).to be > 2
      end

      it 'returns no TourSet objects when requested by non admin' do
        user = create(:user, super: false)
        user.tour_sets = []
        signed_cookie(user)
        get :index, params: { tenant: 'public' }
        expect(response.status).to eq(200)
        expect(json.count).to eq(0)
      end
    end

    describe 'GET #show' do
      context 'unauthenticated' do
        it 'returns a success response and dummy TourSet when no tour is published' do
          get :show, params: { tenant: 'public', id: TourSet.first.to_param }
          expect(response.status).to eq(200)
          expect(attributes[:name]).to eq('....')
        end

        it 'returns a success response and TourSet when TourSet has published tour' do
          Apartment::Tenant.switch! TourSet.last.subdir
          tour = create(:tour, published: true)
          tour.stops << create(:stop)
          get :show, params: { tenant: 'public', id: TourSet.last.to_param }
          expect(response.status).to eq(200)
          expect(attributes[:name]).to eq(TourSet.last.name)
          expect(relationships[:admins][:data]).to be_empty
        end
      end

      context 'authenticated unauthorized' do
        it 'returns a success response and dummy TourSet when no tour is published' do
          user = create(:user, super: false)
          user.tour_sets = []
          signed_cookie(user)
          get :show, params: { tenant: 'public', id: TourSet.first.to_param }
          expect(response.status).to eq(200)
          expect(attributes[:name]).to eq('....')
        end

        it 'returns a success response and TourSet when TourSet has published tour' do
          user = create(:user, super: false)
          user.tour_sets << TourSet.first
          signed_cookie(user)
          get :show, params: { tenant: 'public', id: TourSet.last.to_param }
          expect(response.status).to eq(200)
          expect(attributes[:name]).to eq('....')
        end
      end

      context 'authenticated authorized' do
        it 'returns a success response and TourSet when requested by tenant adamin' do
          user = create(:user, super: false)
          user.tour_sets << TourSet.last
          signed_cookie(user)
          get :show, params: { tenant: 'public', id: TourSet.last.to_param }
          expect(response.status).to eq(200)
          expect(attributes[:name]).to eq(TourSet.last.name)
          expect(relationships[:admins][:data].map { |admin| admin[:id] }).to include(user.id.to_s)
        end

        it 'returns a success response and TourSet when requested by super' do
          user = create(:user, super: true)
          signed_cookie(user)
          get :show, params: { tenant: 'public', id: TourSet.last.to_param }
          expect(response.status).to eq(200)
          expect(attributes[:name]).to eq(TourSet.last.name)
        end
      end
    end

    describe 'POST #create' do
      context 'when unauthenticated and unauthorized' do
        it 'does not create a new TourSet when not super' do
          expect {
            post :create, params: valid_params
          }.to change(TourSet, :count).by(0)
        end

        it 'returns 401' do
          post :create, params: valid_params
          expect(response).to have_http_status(401)
        end
      end

      context 'when authenticated but unauthorized' do
        it 'does not create a new TourSet when not super' do
          user = create(:user, super: false)
          signed_cookie(user)
          expect {
            post :create, params: valid_params
          }.to change(TourSet, :count).by(0)
        end

        it 'returns 401 when not super' do
          user = create(:user, super: false)
          signed_cookie(user)
          post :create, params: valid_params
          expect(response).to have_http_status(401)
        end

        it 'does not create a new TourSet when not super but is a tenant admin' do
          user = create(:user, super: false)
          user.tour_sets << TourSet.second
          signed_cookie(user)
          expect {
            post :create, params: valid_params
          }.to change(TourSet, :count).by(0)
        end

        it 'returns 401 when not super but is a tenant admin' do
          user = create(:user, super: false)
          user.tour_sets << TourSet.first
          signed_cookie(user)
          post :create, params: valid_params
          expect(response).to have_http_status(401)
        end
      end

      context 'when authenticated and authorized' do
        context 'valid params' do
          it 'creates a new TourSet' do
            user = create(:user, super: true)
            signed_cookie(user)
            expect {
              post :create, params: valid_params
            }.to change(TourSet, :count).by(1)
          end

          it 'renders a JSON response with the new tour_set' do
            user = create(:user, super: true)
            signed_cookie(user)
            post :create, params: valid_params
            expect(response).to have_http_status(:created)
            expect(response.content_type).to eq('application/json; charset=utf-8')
          end
        end
      end

      context 'with invalid params' do
        it 'renders a JSON response with errors for the new tour_set' do
          user = create(:user, super: true)
          signed_cookie(user)
          post :create, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe 'PUT #update' do
      context 'when unauthenticated and unauthorized' do
        it 'returns 401' do
          put :update, params: valid_params.merge({ id: TourSet.last.to_param })
          expect(response).to have_http_status(401)
        end
      end

      context 'when authenticated but unauthorized' do
        it 'does not update a TourSet when not super' do
          user = create(:user, super: false)
          signed_cookie(user)
          put :update, params: valid_params.merge({ id: TourSet.first.to_param })
          expect(response).to have_http_status(401)
        end

        it 'does not update TourSet when not super but is a tenant admin' do
          user = create(:user, super: false)
          user.tour_sets << TourSet.second
          signed_cookie(user)
          put :update, params: valid_params.merge({ id: TourSet.second.to_param })
          expect(response).to have_http_status(401)
        end
      end

      context 'when authenticated and authorized' do
        context 'valid params' do
          it 'renders a JSON response with the new tour_set' do
            new_name = Faker::Music::Hiphop.artist
            valid_params[:data][:attributes][:name] = new_name
            user = create(:user, super: true)
            signed_cookie(user)
            put :update, params: valid_params.merge({ id: TourSet.last.to_param })
            expect(response).to have_http_status(200)
            expect(attributes[:name]).to eq(new_name)
          end
        end

        context 'valid params' do
          it 'renders a JSON response with the new tour_set and purges icon' do
            tour_set = create(:tour_set)
            tour_set.update(
              logo_title: Faker::File.file_name(dir: '', ext: 'png', directory_separator: ''),
              base_sixty_four: File.read(Rails.root.join('spec/factories/base64_image.txt'))
            )
            expect(TourSet.find(tour_set.id).logo.attached?).to be true
            serialized_tour_set = JSON.parse(ActiveModelSerializers::Adapter::JsonApi.new(V3::TourSetSerializer.new(tour_set)).to_json).with_indifferent_access
            serialized_tour_set[:data][:attributes][:base_sixty_four] = nil
            serialized_tour_set[:data][:attributes][:logo] = nil
            user = create(:user, super: true)
            signed_cookie(user)
            put :update, params: { data: serialized_tour_set[:data], id: tour_set.id, tenant: 'public' }
            expect(response).to have_http_status(200)
            expect(TourSet.find(tour_set.id).logo.attached?).to be false
          end
        end
      end

      context 'with invalid params' do
        it 'renders a JSON response with errors for the new tour_set' do
          user = create(:user, super: true)
          signed_cookie(user)
          put :update, params: invalid_params.merge({ id: TourSet.first.to_param })
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe 'DELETE #destroy' do
      it 'destroys the requested tour_set' do
        tour_set = create(:tour_set)
        user = create(:user, super: true)
        signed_cookie(user)
        Apartment::Tenant.reset
        expect {
          delete :destroy, params: { id: tour_set.to_param, tenant: Apartment::Tenant.current }
        }.to change(TourSet, :count).by(-1)
      end
    end
  end
end
