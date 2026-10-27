# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(V4::Admin::UsersController, type: :controller) do
  describe 'GET #index' do
    it 'returns 401 when unauthenticated' do
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(response).to(have_http_status(:unauthorized))
    end

    it 'returns 401 when authenticated but not super' do
      user = create(:user, super: false)
      signed_cookie(user)
      tour_set = create(:tour_set)
      get :index, params: { tenant: tour_set.subdir }
      expect(response).to(have_http_status(:unauthorized))
    end

    it 'returns 401 and list of users when authenticated as current tenant admin' do
      user = create(:user, super: false)
      signed_cookie(user)
      tour_set = create(:tour_set)
      user.tour_sets << tour_set
      Apartment::Tenant.switch!(tour_set.subdir)
      get :index, params: { tenant: tour_set.subdir }
      expect(response).to(have_http_status(:unauthorized))
    end

    it "includes each user's tours, by site, with whether they're a student author" do
      signed_cookie(create(:user, super: true))
      tour_set = create(:tour_set)
      author = create(:user)
      Apartment::Tenant.switch!(tour_set.subdir)
      quad = create(:tour, title: 'Quad Walk')
      library = create(:tour, title: 'Library Tour')
      create(:tour_author, tour: quad, user: author)
      create(:tour_author, tour: library, user: author, student: true)

      get :index, params: { tenant: tour_set.subdir }

      entry = v4_json.find { |user| user[:id] == author.id }
      expect(entry[:authored_tours]).to(eq([{
        site: tour_set.name,
        subdir: tour_set.subdir,
        tours: [
          { id: library.id, title: 'Library Tour', student: true },
          { id: quad.id, title: 'Quad Walk', student: false },
        ],
      }]))
    end

    it 'returns 200 and list of users when authenticated as super' do
      create(:user, display_name: nil) # Ensures the sort_by works
      user = create(:user, super: true)
      signed_cookie(user)
      tour_set = create(:tour_set)
      get :index, params: { tenant: tour_set.subdir }
      expect(response).to(have_http_status(:ok))
      expect(v4_json.count).to(eq(User.count))
    end

    it 'returns 401 when bad credentials' do
      tour_set = create(:tour_set)
      invalid_signed_cooke
      get :index, params: { tenant: tour_set.subdir }
      expect(response.status).to(eq(401))
    end
  end

  describe 'GET #show' do
    it 'returns 200 and current user when authenticated and me parameter is present' do
      user = create(:user, super: false)
      User.reindex
      signed_cookie(user)
      get :show, params: { tenant: 'public' }
      expect(response).to(have_http_status(:ok))
      expect(v4_json[:email]).to(eq(user.email))
    end

    it 'returns 401 when unauthenticated and me parameter is present' do
      get :show, params: { tenant: 'public' }
      expect(response.status).to(eq(401))
    end

    it 'returns 401 when bad credentials and me parameter is present' do
      invalid_signed_cooke
      get :show, params: { tenant: 'public' }
      expect(response.status).to(eq(401))
    end
  end

  describe 'DELETE #destroy_me' do
    it 'returns 401 when signed out' do
      delete :destroy_me, params: { tenant: 'public' }
      expect(response).to(have_http_status(:unauthorized))
    end

    it 'deletes the account and its access, but not what the user made' do
      tour_set = create(:tour_set)
      user = create(:user, super: false, tour_sets: [tour_set])
      signed_cookie(user)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      stop = create(:stop, created_by_id: user.id)
      create(:tour_author, tour:, user:)
      create(:access_request, user:, tour_set: create(:tour_set))
      Apartment::Tenant.reset

      delete :destroy_me, params: { tenant: 'public' }

      expect(response).to(have_http_status(:no_content))
      expect(User.exists?(user.id)).to(be(false))
      expect(EcdsRailsAuthEngine::Login.where(user_id: user.id)).to(be_empty)
      expect(TourSetAdmin.where(user_id: user.id)).to(be_empty)
      expect(AccessRequest.where(user_id: user.id)).to(be_empty)
      Apartment::Tenant.switch!(tour_set.subdir)
      expect(TourAuthor.where(user_id: user.id)).to(be_empty)
      expect(Tour.exists?(tour.id)).to(be(true))
      expect(Stop.exists?(stop.id)).to(be(true))
    end

    it 'does not delete the only super user' do
      User.where(super: true).update_all(super: false) # rubocop:disable Rails/SkipsModelValidations
      only_super = create(:user, super: true)
      signed_cookie(only_super)
      delete :destroy_me, params: { tenant: 'public' }
      expect(response).to(have_http_status(:unprocessable_entity))
      expect(User.exists?(only_super.id)).to(be(true))
    end
  end
end
