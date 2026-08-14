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
