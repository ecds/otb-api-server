# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V3::UsersController, type: :controller do
  describe 'GET #index' do
    context 'unauthorized' do
      it 'returns a success response but empty json when request is unauthenticated' do
        create_list(:user, rand(4..5))
        get :index, params: { tenant: Apartment::Tenant.current }
        expect(response.status).to eq(200)
        expect(json).to be_empty
      end

      it 'returns a success response but empty json when request is unauthenticated' do
        create_list(:user, rand(4..5))
        user = User.last
        user.update(super: false)
        signed_cookie(user)
        get :index, params: { tenant: Apartment::Tenant.current }
        expect(response.status).to eq(200)
        expect(json).to be_empty
      end
    end

    context 'authorized' do
      it 'returns current user when requested by current user' do
        user = create(:user)
        signed_cookie(user)
        get :index, params: { tenant: Apartment::Tenant.current, me: true }
        expect(response.status).to eq(200)
        expect(json[:id]).to eq(user.id.to_s)
      end

      it 'returns list of users when requested by super' do
        create_list(:user, rand(4..7))
        user = User.last
        user.update(super: true)
        signed_cookie(user)
        get :index, params: { tenant: Apartment::Tenant.current }
        expect(json.count).to eq(User.count)
      end
    end
  end

  describe 'GET #show' do
    let(:user) { create(:user, super: false) }
    let(:other_user) { create(:user, super: false) }

    context 'unauthorized' do
      it 'returns 401 when unauthenticated' do
        signed_cookie(user)
        get :show, params: { id: other_user.to_param, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(401)
      end

      it 'returns 401 when unauthorized tenant admin' do
        user.tour_sets << create(:tour_set)
        signed_cookie(user)
        get :show, params: { id: other_user.to_param, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(401)
      end

      it 'returns 401 when unauthorized tour author' do
        user.tours << create(:tour)
        signed_cookie(user)
        get :show, params: { id: other_user.to_param, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(401)
      end
    end

    context 'authorized' do
      it 'returns user when requested by self' do
        signed_cookie(user)
        get :show, params: { id: user.to_param, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(200)
        expect(json[:id]).to eq(user.id.to_s)
      end

      it 'returns user when requested by super' do
        user.update(super: true)
        signed_cookie(user)
        get :show, params: { id: other_user.to_param, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(200)
        expect(json[:id]).to eq(other_user.id.to_s)
      end

    end
  end

  describe 'POST #create' do
    let(:user) { create(:user, super: false) }
    let(:valid_params) { { data: { type: 'users', attributes: { display_name: Faker::Music::Hiphop.artist, email: Faker::Internet.safe_email } }, tenant: 'public' } }

    context 'unauthorized' do
      it 'does not create a new User when unauthenticated' do
        expect do
          post :create, params: valid_params
        end.to change(User, :count).by(0)
      end

      it 'does not create a new User for tenant admin' do
        user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
        signed_cookie(user)
        expect do
          post :create, params: valid_params
        end.to change(User, :count).by(0)
      end

      it 'does not create a new User for tour author' do
        user.tours << create(:tour)
        signed_cookie(user)
        expect do
          post :create, params: valid_params
        end.to change(User, :count).by(0)
      end
    end

    context 'authorized' do
      it 'creates a new User for super' do
        user.update(super: true)
        signed_cookie(user)
        expect do
          post :create, params: valid_params
        end.to change(User, :count).by(1)
      end

      it 'does not create a new User for super with invalid_params' do
        user.update(super: true)
        valid_params[:data][:attributes].delete(:email)
        signed_cookie(user)
        expect do
          post :create, params: valid_params
        end.to change(User, :count).by(0)
      end

      it 'responds with errors when creating a new User for super with invalid_params' do
        user.update(super: true)
        valid_params[:data][:attributes].delete(:email)
        signed_cookie(user)
        post :create, params: valid_params
        expect(response.status).to eq(422)
        expect(errors).to include('Email can\'t be blank')
      end
    end
  end

  describe 'PUT #update' do
    context 'unauthorized' do
      it 'does not update when unauthenticated' do
        user = create(:user, super: false)
        initial_display_name = user.display_name
        new_display_name = Faker::Music::Hiphop.artist
        update_params = { id: user.to_param, tenant: 'public', data: { type: 'users', attributes: { display_name: new_display_name } } }
        put :update, params: update_params
        expect(response.status).to eq(401)
        user.reload
        expect(user.display_name).not_to eq(new_display_name)
      end

      it 'does not update when authenticated as user not the one being updated' do
        user = create(:user, super: false)
        user_to_update = create(:user)
        user.tour_sets << create(:tour_set)
        initial_display_name = user_to_update.display_name
        new_display_name = Faker::Music::Hiphop.artist
        update_params = { id: user_to_update.to_param, tenant: 'public', data: { type: 'users', attributes: { display_name: new_display_name } } }
        signed_cookie(user)
        put :update, params: update_params
        expect(response.status).to eq(401)
        user_to_update.reload
        expect(user_to_update.display_name).not_to eq(new_display_name)
      end

      it 'does not update when authenticated by tenant admin' do
        user = create(:user)
        user_to_update = create(:user)
        user.tour_sets << create(:tour_set)
        initial_display_name = user_to_update.display_name
        new_display_name = "#{Faker::Music::Hiphop.artist}!"
        update_params = { id: user_to_update.to_param, tenant: 'public', data: { type: 'users', attributes: { display_name: new_display_name } } }
        signed_cookie(user)
        put :update, params: update_params
        expect(response.status).to eq(401)
        user_to_update.reload
        expect(user_to_update.display_name).not_to eq(new_display_name)
      end

      it 'does not update when authenticated by tour author' do
        user = create(:user)
        user_to_update = create(:user)
        user.tours << create(:tour)
        initial_display_name = user_to_update.display_name
        new_display_name = Faker::Music::Hiphop.artist
        update_params = { id: user_to_update.to_param, tenant: 'public', data: { type: 'users', attributes: { display_name: new_display_name } } }
        signed_cookie(user)
        put :update, params: update_params
        expect(response.status).to eq(401)
        user_to_update.reload
        expect(user_to_update.display_name).not_to eq(new_display_name)
      end
    end

    context 'authorized' do
      it 'updates user when requested by self' do
        user = create(:user)
        initial_display_name = Faker::Music::Hiphop.artist
        new_display_name = Faker::Music::Hiphop.artist
        update_params = { id: user.to_param, tenant: 'public', data: { type: 'users', attributes: { display_name: new_display_name } } }
        signed_cookie(user)
        put :update, params: update_params
        expect(response.status).to eq(200)
        user.reload
        expect(user.display_name).to eq(new_display_name)
      end

      it 'updates user when requested by super' do
        user = create(:user, super: true)
        user_to_update = create(:user)
        initial_display_name = user_to_update.display_name
        new_display_name = Faker::Music::Hiphop.artist
        update_params = { id: user_to_update.to_param, tenant: 'public', data: { type: 'users', attributes: { display_name: new_display_name } } }
        signed_cookie(user)
        put :update, params: update_params
        expect(response.status).to eq(200)
        user_to_update.reload
        expect(user_to_update.display_name).to eq(new_display_name)
      end

      it 'returns 422 when email in nil' do
        user = create(:user, super: true)
        user_to_update = create(:user)
        initial_email = user_to_update.email
        update_params = { id: user_to_update.to_param, tenant: 'public', data: { type: 'users', attributes: { email: nil } } }
        signed_cookie(user)
        put :update, params: update_params
        expect(response.status).to eq(422)
        expect(errors).to include('Email can\'t be blank')
        user_to_update.reload
        expect(user_to_update.email).to eq(initial_email)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'unauthorized' do
      it 'does not destroy the requested user when unauthenticated' do
        user = create(:user)
        expect do
          delete :destroy, params: { id: user.to_param, tenant: 'public' }
        end.to change(User, :count).by(0)
      end

      it 'does not destroy the requested user when authenticated' do
        user = create(:user)
        signed_cookie(user)
        expect do
          delete :destroy, params: { id: user.to_param, tenant: 'public' }
        end.to change(User, :count).by(0)
      end
    end

    context 'authorized' do
      it 'destroys user when requested by super' do
        super_user = create(:user, super: true)
        user = create(:user)
        signed_cookie(super_user)
        expect do
          delete :destroy, params: { id: user.to_param, tenant: 'public' }
        end.to change(User, :count).by(-1)
      end
    end
  end
end
