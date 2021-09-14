# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V3::TourFlatPagesController, type: :controller do
  def data(tour, flat_page, position = 1)
    {
      type: 'tour_flat_pages',
      attributes: { position: position },
      relationships: {
        tour: { data: { type: 'tours', id: tour.id } },
        flat_page: { data: { type: 'flat_pages', id: flat_page.id } }
      }
    }
  end

  describe 'GET #index' do
    it 'returns a 200 response and empty tour when none are part of a published tour' do
      Tour.all.each { |tour| tour.update(published: false) }
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(json).to be_empty
      expect(response.status).to eq(200)
    end

    it 'returns a 200 response and only tour flat_pages that are part of a published tour' do
      create_list(:tour_with_flat_pages, 5, theme: create(:theme), mode: create(:mode))
      Tour.first.update(published: true) if Tour.published.empty?
      Tour.last.update(published: false) if Tour.published.count == Tour.count
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(response.status).to eq(200)
      expect(json.count).to eq(Tour.published.map { |tour| tour.tour_flat_pages.count }.sum)
     end

    it 'returns a 200 response when requeted by slug' do
      tour = create(:tour_with_flat_pages)
      tour.update(published: true)
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(response.status).to eq(200)
      expect(json.count).to eq(FlatPage.count)
    end

    it 'returns a 200 response when request is authenticated by tenant admin and tour is unpublished' do
      tour = create(:tour_with_flat_pages, published: false)
      tour.update(published: false)
      user = create(:user)
      user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
      signed_cookie(user)
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(response.status).to eq(200)
      expect(json.count).to eq(FlatPage.count)
    end

    it 'returns a 200 response when request is authenticated by tour author and tour is unpublished' do
      tour = create(:tour_with_flat_pages, published: false)
      tour.update(published: false)
      user = create(:user)
      user.tour_sets = []
      user.tours << tour
      signed_cookie(user)
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(response.status).to eq(200)
      expect(json.count).to eq(FlatPage.count)
    end
  end

  describe 'GET #show' do
    it 'returns a 200 response' do
      tour = create(:tour_with_flat_pages)
      tour.update(published: true)
      get :show, params: { tenant: Apartment::Tenant.current, id: tour.tour_flat_pages.first.id }
      expect(response.status).to eq(200)
      expect(relationships[:tour][:data][:id]).to eq(tour.id.to_s)
    end

    it 'returns a 200 response when request is authenticated by tour author and tour is unpublished' do
      tour = create(:tour_with_flat_pages)
      tour.update(published: false)
      user = create(:user)
      user.tour_sets = []
      user.tours << tour
      signed_cookie(user)
      get :show, params: { tenant: Apartment::Tenant.current, id: tour.tour_flat_pages.first.id }
      expect(response.status).to eq(200)
      expect(relationships[:tour][:data][:id]).to eq(tour.id.to_s)
    end

    it 'returns a 200 response when request is authenticated by tenant admin and tour is unpublished' do
      tour = create(:tour_with_flat_pages)
      tour.update(published: false)
      user = create(:user)
      user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
      signed_cookie(user)
      get :show, params: { tenant: Apartment::Tenant.current, id: tour.tour_flat_pages.first.id }
      expect(response.status).to eq(200)
      expect(relationships[:tour][:data][:id]).to eq(tour.id.to_s)
    end

    it 'returns a 200 response and empty json when tour is unpublished and request is not authenticated' do
      tour = create(:tour_with_flat_pages)
      tour.update(published: false)
      get :show, params: { tenant: Apartment::Tenant.current, id: tour.tour_flat_pages.first.id }
      expect(response.status).to eq(200)
      expect(json).to be_empty
    end

    it 'returns a 200 response and empty json when tour is unpublished and request is authenticated by someone who is nither a tenant admin or tour author' do
      tour = create(:tour_with_flat_pages)
      tour.update(published: false)
      user = create(:user)
      user.tours = []
      user.tour_sets = []
      signed_cookie(user)
      get :show, params: { tenant: Apartment::Tenant.current, id: tour.tour_flat_pages.first.id }
      expect(response.status).to eq(200)
      expect(json).to be_empty
    end
  end

  # TourFlatPage objects are NOT created via tha API. Every test should return 401
  describe 'POST #create' do
    context 'with valid params' do
      it 'return 405 when unauthenciated' do
        tour = create(:tour)
        flat_page = create(:flat_page)
        post :create, params: { data: data(tour, flat_page), tenant: TourSet.first.subdir }
        expect(response.status).to eq(405)
      end

      it 'return 405 when authenciated but not an admin for current tenant' do
        tour = create(:tour)
        flat_page = create(:flat_page)
        original_tour_flat_page_count = TourFlatPage.count
        user = create(:user)
        user.update(super: false)
        user.tour_sets = []
        user.tours = []
        signed_cookie(user)
        post :create, params: { data:  data(tour, flat_page), tenant: Apartment::Tenant.current }
        expect(response.status).to eq(405)
        expect(original_tour_flat_page_count).to eq(TourFlatPage.count)
      end

      it 'return 405 when authenciated but an admin for current tenant' do
        tour = create(:tour)
        flat_page = create(:flat_page)
        original_tour_flat_page_count = TourFlatPage.count
        user = create(:user)
        user.update(super: false)
        user.tours = []
        user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
        signed_cookie(user)
        post :create, params: { data:  data(tour, flat_page), tenant: Apartment::Tenant.current }
        expect(response.status).to eq(405)
        expect(original_tour_flat_page_count).to eq(TourFlatPage.count)
      end

      it 'return 405 when authenciated by super' do
        tour = create(:tour)
        flat_page = create(:flat_page)
        original_tour_flat_page_count = TourFlatPage.count
        user = create(:user)
        user.tours = []
        user.tour_sets = []
        user.update(super: true)
        signed_cookie(user)
        post :create, params: { data:  data(tour, flat_page), tenant: Apartment::Tenant.current }
        expect(response.status).to eq(405)
        expect(original_tour_flat_page_count).to eq(TourFlatPage.count)
      end

      it 'return 405 when authenciated by tour author' do
        tour = create(:tour)
        flat_page = create(:flat_page)
        original_tour_flat_page_count = TourFlatPage.count
        user = create(:user)
        user.tours << tour
        user.tour_sets = []
        user.update(super: false)
        signed_cookie(user)
        post :create, params: { data:  data(tour, flat_page), tenant: Apartment::Tenant.current }
        expect(response.status).to eq(405)
        expect(original_tour_flat_page_count).to eq(TourFlatPage.count)
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      it 'return 401 when unauthenciated' do
        tour = create(:tour)
        flat_page = create(:flat_page)
        tour.flat_pages << flat_page
        request_data = data(tour, flat_page, 4)
        request_data[:id] = TourFlatPage.find_by(tour: tour, flat_page: flat_page).id
        post :update, params: { id: request_data[:id], data: request_data, tenant: TourSet.first.subdir }
        expect(response.status).to eq(401)
      end

      it 'return 401 when authenciated but not an admin for current tenant' do
        tour = create(:tour)
        flat_page = create(:flat_page)
        tour.flat_pages << flat_page
        user = create(:user)
        user.update(super: false)
        user.tour_sets = []
        user.tours = []
        signed_cookie(user)
        request_data = data(tour, flat_page, 5)
        request_data[:id] = TourFlatPage.find_by(tour: tour, flat_page: flat_page).id
        post :update, params: { id: request_data[:id], data: request_data, tenant: TourSet.first.subdir }
        expect(response.status).to eq(401)
      end

      it 'return 200 and updated tour when authenciated but an admin for current tenant' do
        tour = create(:tour)
        flat_pages = create_list(:flat_page, 5)
        flat_pages.each { |flat_page| tour.flat_pages << flat_page }
        tour.save
        flat_page = FlatPage.find(flat_pages.first.id)
        tour.flat_pages << flat_page
        user = create(:user)
        user.update(super: false)
        user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
        user.tours = []
        signed_cookie(user)
        tour_flat_page = TourFlatPage.find_by(tour: tour, flat_page: flat_page)
        tour_flat_page.update(position: 2)
        expect(TourFlatPage.find(tour_flat_page.id).position).to eq(2)
        request_data = data(tour, flat_page, 5)
        request_data[:id] = tour_flat_page.id
        post :update, params: { id: tour_flat_page.id, data: request_data, tenant: TourSet.first.subdir }
        expect(response.status).to eq(200)
        expect(attributes[:position]).not_to eq('5')
        expect(TourFlatPage.find(tour_flat_page.id).position).to eq(5)
      end

      it 'return 200 and updated tour when authenciated by super' do
        tour = create(:tour)
        flat_pages = create_list(:flat_page, 5)
        flat_pages.each { |flat_page| tour.flat_pages << flat_page }
        tour.save
        flat_page = FlatPage.find(flat_pages.first.id)
        tour.flat_pages << flat_page
        user = create(:user)
        user.update(super: true)
        user.tour_sets = []
        user.tours = []
        signed_cookie(user)
        tour_flat_page = TourFlatPage.find_by(tour: tour, flat_page: flat_page)
        tour_flat_page.update(position: 3)
        expect(TourFlatPage.find(tour_flat_page.id).position).to eq(3)
        request_data = data(tour, flat_page, 4)
        request_data[:id] = tour_flat_page.id
        post :update, params: { id: tour_flat_page.id, data: request_data, tenant: TourSet.first.subdir }
        expect(response.status).to eq(200)
        expect(attributes[:position]).not_to eq('4')
        expect(TourFlatPage.find(tour_flat_page.id).position).to eq(4)
      end

      it 'return 200 and updated tour when authenciated by tour author' do
        tour = create(:tour)
        flat_pages = create_list(:flat_page, 5)
        flat_pages.each { |flat_page| tour.flat_pages << flat_page }
        tour.save
        flat_page = FlatPage.find(flat_pages.first.id)
        tour.flat_pages << flat_page
        user = create(:user)
        user.update(super: false)
        user.tour_sets = []
        user.tours << tour
        signed_cookie(user)
        tour_flat_page = TourFlatPage.find_by(tour: tour, flat_page: flat_page)
        tour_flat_page.update(position: 6)
        expect(TourFlatPage.find(tour_flat_page.id).position).to eq(6)
        request_data = data(tour, flat_page, 1)
        request_data[:id] = tour_flat_page.id
        post :update, params: { id: tour_flat_page.id, data: request_data, tenant: TourSet.first.subdir }
        expect(response.status).to eq(200)
        expect(attributes[:position]).not_to eq('1')
        expect(TourFlatPage.find(tour_flat_page.id).position).to eq(1)
      end

      it 'returns 422 when params are invalid' do
        tour_flat_page = create(:tour_flat_page)
        user = create(:user, super: true)
        invalid_params = { type: 'tour_flat_pages',  attributes: {}, relationships: { tour: { data: nil }, flat_page: { data: nil } } }
        signed_cookie(user)
        post :update, params: { id: tour_flat_page.id, data: invalid_params, tenant: TourSet.first.subdir }
        expect(response.status).to eq(422)
        expect(errors).to include('Tour must exist')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'return 405 when unauthenciated' do
      tour = create(:tour)
      flat_page = create(:flat_page)
      tour.flat_pages << flat_page
      tour_flat_page = TourFlatPage.find_by(tour: tour, flat_page: flat_page)
      post :destroy, params: { id: tour_flat_page.id, tenant: TourSet.first.subdir }
      expect(response.status).to eq(405)
    end

    it 'return 405 when authenciated but not an admin for current tenant' do
      tour = create(:tour)
      flat_page = create(:flat_page)
      tour.flat_pages << flat_page
      tour_flat_page = TourFlatPage.find_by(tour: tour, flat_page: flat_page)
      user = create(:user)
      user.update(super: false)
      user.tour_sets = []
      signed_cookie(user)
      post :destroy, params: { id: tour_flat_page.id, tenant: TourSet.first.subdir }
      expect(response.status).to eq(405)
    end

    it 'return 405 and one less tour when authenciated but an admin for current tenant' do
      tour = create(:tour)
      flat_page = create(:flat_page)
      tour.flat_pages << flat_page
      tour_flat_page = TourFlatPage.find_by(tour: tour, flat_page: flat_page)
      user = create(:user)
      user.update(super: false)
      user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
      signed_cookie(user)
      tour_count = Tour.count
      post :destroy, params: { id: tour_flat_page.id, tenant: Apartment::Tenant.current }
      expect(response.status).to eq(405)
      expect(Tour.count).to eq(tour_count)
    end

    it 'return 405 and one less tour when authenciated by super' do
      tour = create(:tour)
      flat_page = create(:flat_page)
      tour.flat_pages << flat_page
      tour_flat_page = TourFlatPage.find_by(tour: tour, flat_page: flat_page)
      user = create(:user)
      user.tour_sets = []
      user.update(super: true)
      signed_cookie(user)
      tour_count = Tour.count
      post :destroy, params: { id: tour_flat_page.id, tenant: Apartment::Tenant.current }
      expect(response.status).to eq(405)
      expect(Tour.count).to eq(tour_count)
    end

    it 'return 405 and one less tour when authenciated by tour author' do
      tour = create(:tour)
      flat_page = create(:flat_page)
      tour.flat_pages << flat_page
      tour_flat_page = TourFlatPage.find_by(tour: tour, flat_page: flat_page)
      user = create(:user)
      user.update(super: false)
      user.tour_sets = []
      user.tours << tour
      signed_cookie(user)
      new_title = Faker::Name.unique.name
      tour_count = Tour.count
      post :destroy, params: { id: tour_flat_page.id, tenant: Apartment::Tenant.current }
      expect(response.status).to eq(405)
      expect(Tour.count).to eq(tour_count)
    end
  end
end
