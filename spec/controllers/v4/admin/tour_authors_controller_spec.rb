# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(V4::Admin::TourAuthorsController, type: :controller) do
  describe 'GET #index' do
    it 'returns 401 when unauthenticated' do
      tour_set = create(:tour_set)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      get :index, params: { tenant: tour_set.subdir, tour_id: tour.id }
      expect(response).to(have_http_status(:unauthorized))
    end

    it 'returns 401 when authenticated but not a tenant admin or super' do
      user = create(:user, super: false, tour_sets: [])
      signed_cookie(user)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      get :index, params: { tenant: tour_set.subdir, tour_id: tour.id }
      expect(response).to(have_http_status(:unauthorized))
    end

    it 'returns 401 for a mere tour author (not an admin)' do
      tour_set = create(:tour_set)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      author = create(:user, super: false, tour_sets: [])
      create(:tour_author, tour:, user: author)
      signed_cookie(author)
      get :index, params: { tenant: tour_set.subdir, tour_id: tour.id }
      expect(response).to(have_http_status(:unauthorized))
    end

    it 'returns the users for a tour when authenticated as current tenant admin' do
      tour_set = create(:tour_set)
      admin = create(:user, super: false, tour_sets: [tour_set])
      signed_cookie(admin)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      authors = create_list(:user, 3)
      authors.each { |author| create(:tour_author, tour:, user: author) }

      get :index, params: { tenant: tour_set.subdir, tour_id: tour.id }

      expect(response).to(have_http_status(:ok))
      expect(v4_json.length).to(eq(3))
      expect(v4_json.map { |u| u[:id] }).to(match_array(authors.map(&:id)))
    end

    it 'returns the users for a tour when authenticated as super' do
      tour_set = create(:tour_set)
      super_user = create(:user, super: true)
      signed_cookie(super_user)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      author = create(:user)
      create(:tour_author, tour:, user: author)

      get :index, params: { tenant: tour_set.subdir, tour_id: tour.id }

      expect(response).to(have_http_status(:ok))
      expect(v4_json.length).to(eq(1))
      expect(v4_json.first[:id]).to(eq(author.id))
    end

    it 'returns an empty array when the tour has no authors' do
      tour_set = create(:tour_set)
      admin = create(:user, super: false, tour_sets: [tour_set])
      signed_cookie(admin)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)

      get :index, params: { tenant: tour_set.subdir, tour_id: tour.id }

      expect(response).to(have_http_status(:ok))
      expect(v4_json).to(eq([]))
    end

    it 'only returns authors for the requested tour' do
      tour_set = create(:tour_set)
      admin = create(:user, super: false, tour_sets: [tour_set])
      signed_cookie(admin)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      other_tour = create(:tour)
      author = create(:user)
      create(:tour_author, tour:, user: author)
      create(:tour_author, tour: other_tour, user: create(:user))

      get :index, params: { tenant: tour_set.subdir, tour_id: tour.id }

      expect(v4_json.length).to(eq(1))
      expect(v4_json.first[:id]).to(eq(author.id))
    end
  end

  describe 'POST #create' do
    it 'returns 401 when unauthenticated' do
      tour_set = create(:tour_set)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      user = create(:user)
      post :create, params: { tenant: tour_set.subdir, tour_id: tour.id, user_id: user.id }
      expect(response).to(have_http_status(:unauthorized))
    end

    it 'returns 401 when authenticated but not a tenant admin or super' do
      requester = create(:user, super: false, tour_sets: [])
      signed_cookie(requester)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      user = create(:user)
      post :create, params: { tenant: tour_set.subdir, tour_id: tour.id, user_id: user.id }
      expect(response).to(have_http_status(:unauthorized))
    end

    it 'returns 401 for a mere tour author (not an admin)' do
      tour_set = create(:tour_set)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      author = create(:user, super: false, tour_sets: [])
      create(:tour_author, tour:, user: author)
      signed_cookie(author)
      user = create(:user)
      post :create, params: { tenant: tour_set.subdir, tour_id: tour.id, user_id: user.id }
      expect(response).to(have_http_status(:unauthorized))
    end

    it 'creates a tour author when authenticated as current tenant admin' do
      tour_set = create(:tour_set)
      admin = create(:user, super: false, tour_sets: [tour_set])
      signed_cookie(admin)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      user = create(:user)

      expect do
        post(:create, params: { tenant: tour_set.subdir, tour_id: tour.id, user_id: user.id })
      end.to(change(TourAuthor, :count).by(1))
      expect(response).to(have_http_status(:created))
      expect(v4_json[:tour_id]).to(eq(tour.id))
      expect(v4_json[:user_id]).to(eq(user.id))
    end

    it 'creates a tour author when authenticated as super' do
      tour_set = create(:tour_set)
      super_user = create(:user, super: true)
      signed_cookie(super_user)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      user = create(:user)

      expect do
        post(:create, params: { tenant: tour_set.subdir, tour_id: tour.id, user_id: user.id })
      end.to(change(TourAuthor, :count).by(1))
      expect(response).to(have_http_status(:created))
    end

    it 'returns 422 and does not create a record when user_id is missing' do
      tour_set = create(:tour_set)
      admin = create(:user, super: false, tour_sets: [tour_set])
      signed_cookie(admin)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)

      expect do
        post(:create, params: { tenant: tour_set.subdir, tour_id: tour.id })
      end.not_to(change(TourAuthor, :count))
      expect(response).to(have_http_status(:unprocessable_entity))
    end

    it 'returns 422 and does not create a record when tour_id is missing' do
      tour_set = create(:tour_set)
      admin = create(:user, super: false, tour_sets: [tour_set])
      signed_cookie(admin)
      Apartment::Tenant.switch!(tour_set.subdir)
      user = create(:user)

      expect do
        post(:create, params: { tenant: tour_set.subdir, user_id: user.id })
      end.not_to(change(TourAuthor, :count))
      expect(response).to(have_http_status(:unprocessable_entity))
    end

    it 'returns 422 and does not create a duplicate when the user is already an author of the tour' do
      tour_set = create(:tour_set)
      admin = create(:user, super: false, tour_sets: [tour_set])
      signed_cookie(admin)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      user = create(:user)
      create(:tour_author, tour:, user:)

      expect do
        post(:create, params: { tenant: tour_set.subdir, tour_id: tour.id, user_id: user.id })
      end.not_to(change(TourAuthor, :count))
      expect(response).to(have_http_status(:unprocessable_entity))
    end

    it 'creates a tour author by username when authenticated as current tenant admin' do
      tour_set = create(:tour_set)
      admin = create(:user, super: false, tour_sets: [tour_set])
      signed_cookie(admin)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      user = create(:user, display_name: 'Jane Doe')

      expect do
        post(:create, params: { tenant: tour_set.subdir, tour_id: tour.id, username: 'Jane Doe' })
      end.to(change(TourAuthor, :count).by(1))
      expect(response).to(have_http_status(:created))
      expect(v4_json[:tour_id]).to(eq(tour.id))
      expect(v4_json[:user_id]).to(eq(user.id))
    end

    it 'creates a tour author by username when authenticated as super' do
      tour_set = create(:tour_set)
      super_user = create(:user, super: true)
      signed_cookie(super_user)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      user = create(:user, display_name: 'Jane Doe')

      expect do
        post(:create, params: { tenant: tour_set.subdir, tour_id: tour.id, username: 'Jane Doe' })
      end.to(change(TourAuthor, :count).by(1))
      expect(response).to(have_http_status(:created))
      expect(v4_json[:user_id]).to(eq(user.id))
    end

    it 'prefers username over user_id when both are given' do
      tour_set = create(:tour_set)
      admin = create(:user, super: false, tour_sets: [tour_set])
      signed_cookie(admin)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      by_username = create(:user, display_name: 'Jane Doe')
      by_id = create(:user)

      post(
        :create,
        params: { tenant: tour_set.subdir, tour_id: tour.id, username: 'Jane Doe', user_id: by_id.id },
      )

      expect(response).to(have_http_status(:created))
      expect(v4_json[:user_id]).to(eq(by_username.id))
    end

    it 'returns 422 and does not create a record when username does not match any user' do
      tour_set = create(:tour_set)
      admin = create(:user, super: false, tour_sets: [tour_set])
      signed_cookie(admin)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)

      expect do
        post(:create, params: { tenant: tour_set.subdir, tour_id: tour.id, username: 'Nobody Here' })
      end.not_to(change(TourAuthor, :count))
      expect(response).to(have_http_status(:unprocessable_entity))
    end

    it 'returns 422 and does not create a duplicate when the user found by username is already an author' do
      tour_set = create(:tour_set)
      admin = create(:user, super: false, tour_sets: [tour_set])
      signed_cookie(admin)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      user = create(:user, display_name: 'Jane Doe')
      create(:tour_author, tour:, user:)

      expect do
        post(:create, params: { tenant: tour_set.subdir, tour_id: tour.id, username: 'Jane Doe' })
      end.not_to(change(TourAuthor, :count))
      expect(response).to(have_http_status(:unprocessable_entity))
    end
  end

  describe 'DELETE #destroy' do
    it 'returns 401 when unauthenticated' do
      tour_set = create(:tour_set)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      tour_author = create(:tour_author, tour:)
      delete :destroy,
        params: { tenant: tour_set.subdir, id: 1, tour_id: tour.id, user_id: tour_author.user_id }
      expect(response).to(have_http_status(:unauthorized))
    end

    it 'returns 401 when authenticated but not a tenant admin or super' do
      user = create(:user, super: false, tour_sets: [])
      signed_cookie(user)
      tour_set = create(:tour_set)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      tour_author = create(:tour_author, tour:)
      delete :destroy,
        params: { tenant: tour_set.subdir, id: 1, tour_id: tour.id, user_id: tour_author.user_id }
      expect(response).to(have_http_status(:unauthorized))
    end

    it 'removes the tour author when authenticated as current tenant admin' do
      tour_set = create(:tour_set)
      admin = create(:user, super: false, tour_sets: [tour_set])
      signed_cookie(admin)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      tour_author = create(:tour_author, tour:)

      expect do
        delete(
          :destroy,
          params: { tenant: tour_set.subdir, id: 1, tour_id: tour.id, user_id: tour_author.user_id },
        )
      end.to(change(TourAuthor, :count).by(-1))
      expect(response).to(have_http_status(:no_content))
    end

    it 'removes the tour author when authenticated as super' do
      tour_set = create(:tour_set)
      super_user = create(:user, super: true)
      signed_cookie(super_user)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      tour_author = create(:tour_author, tour:)

      expect do
        delete(
          :destroy,
          params: { tenant: tour_set.subdir, id: 1, tour_id: tour.id, user_id: tour_author.user_id },
        )
      end.to(change(TourAuthor, :count).by(-1))
      expect(response).to(have_http_status(:no_content))
    end

    it 'only removes the tour author matching both tour_id and user_id' do
      tour_set = create(:tour_set)
      admin = create(:user, super: false, tour_sets: [tour_set])
      signed_cookie(admin)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)
      other_tour = create(:tour)
      author = create(:user)
      create(:tour_author, tour: other_tour, user: author)
      matching_tour_author = create(:tour_author, tour:, user: author)

      delete :destroy,
        params: { tenant: tour_set.subdir, id: 1, tour_id: tour.id, user_id: author.id }

      expect(response).to(have_http_status(:no_content))
      expect(TourAuthor.exists?(matching_tour_author.id)).to(be(false))
      expect(TourAuthor.exists?(tour_id: other_tour.id, user_id: author.id)).to(be(true))
    end

    it 'returns 404 without crashing when tour_id/user_id do not match a tour author' do
      tour_set = create(:tour_set)
      admin = create(:user, super: false, tour_sets: [tour_set])
      signed_cookie(admin)
      Apartment::Tenant.switch!(tour_set.subdir)
      tour = create(:tour)

      delete :destroy,
        params: { tenant: tour_set.subdir, id: 1, tour_id: tour.id, user_id: 999_999 }

      expect(response).to(have_http_status(:not_found))
    end
  end
end
