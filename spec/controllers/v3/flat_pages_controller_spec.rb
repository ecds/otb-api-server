require 'rails_helper'

RSpec.describe V3::FlatPagesController, type: :controller do
  describe 'GET #index' do
    it 'returns a 200 response with flat_pages connected to published tours' do
      create_list(:tour_with_flat_pages, 5, theme: create(:theme), mode: create(:mode))
      Tour.first.update(published: true) if Tour.published.empty?
      Tour.last.update(published: false)
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(response.status).to eq(200)
      expect(Tour.count).to be > Tour.published.count
      json.each do |flat_page|
        expect(FlatPage.find(flat_page[:id]).tours.any? { |tour| tour.published })
      end
      expect(json.count).to be < FlatPage.count
    end

    it 'returns a 200 response with no flat_pages when request is authenticated by person with no access' do
      create_list(:tour_with_flat_pages, 5, theme: create(:theme), mode: create(:mode))
      Tour.first.update(published: true) if Tour.published.empty?
      Tour.last.update(published: false) if Tour.published.count == Tour.count
      user = create(:user)
      user.tour_sets = []
      user.tours = []
      signed_cookie(user)
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(response.status).to eq(200)
      expect(Tour.count).to be > Tour.published.count
      json.each do |flat_page|
        expect(FlatPage.find(flat_page[:id]).tours.any? { |tour| tour.published })
      end
      expect(json.count).to be == FlatPage.all.reject {|fp| !fp.published}.count
    end

    it 'returns a 200 response with flat_pages when request is authenticated by tenant admin and tour is unpublished' do
      tour = create(:tour_with_flat_pages, published: false)
      tour.update(published: false)
      user = create(:user)
      user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
      signed_cookie(user)
      get :index, params: { tenant: tour.tenant }
      expect(FlatPage.count).to be > 1
      expect(response.status).to eq(200)
      expect(json.count).to eq(FlatPage.count)
    end

    it 'returns a 200 response when request is authenticated by tour author and tour is unpublished' do
      tour = create(:tour_with_flat_pages)
      tour.update(published: false)
      create_list(:flat_page, 7)
      user = create(:user)
      user.tour_sets = []
      user.tours << tour
      signed_cookie(user)
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(response.status).to eq(200)
      expect(json.count).to eq(tour.flat_pages.count)
      expect(json.count).to be < FlatPage.count
    end
  end

  describe 'GET #show' do
    it 'returns a 200 response that is empty stop' do
      tour = create(:tour)
      tour.update(published: false)
      create_list(:flat_page, 3)
      FlatPage.all.each { |flat_page| tour.flat_pages << flat_page }
      # Make sure the flat page is only associated with the newly created tour
      tour.flat_pages.last.update(tours: [tour])
      get :show, params: { tenant: Apartment::Tenant.current, id: tour.flat_pages.last.id }
      expect(response.status).to eq(200)
      expect(json[:id]).to eq(tour.flat_pages.last.id.to_s)
      expect(attributes[:title]).to be_nil
    end

    it 'returns a 200 response and stop when stop is part of published tour' do
      tour = create(:tour)
      tour.update(published: true)
      create_list(:flat_page, 3)
      FlatPage.all.each { |flat_page| tour.flat_pages << flat_page }
      tour.flat_pages.last.update(tours: [tour])
      get :show, params: { tenant: Apartment::Tenant.current, id: tour.flat_pages.last.id }
      expect(response.status).to eq(200)
      expect(attributes[:title]).to eq(tour.flat_pages.last.title)
    end

    it 'returns a 200 response that is empty stop when request is authenticated by someone w/o permission' do
      tour = create(:tour)
      tour.update(published: false)
      create_list(:flat_page, 3)
      FlatPage.all.each { |flat_page| tour.flat_pages << flat_page }
      tour.flat_pages.last.update(tours: [tour])
      user = create(:user)
      user.update(super: false)
      user.tours = []
      user.tour_sets = []
      signed_cookie(user)
      get :show, params: { tenant: Apartment::Tenant.current, id: tour.flat_pages.last.id }
      expect(response.status).to eq(200)
      expect(json[:id]).to eq(tour.flat_pages.last.id.to_s)
      expect(attributes[:title]).to be_nil
    end

    it 'returns a 200 response that is a stop when request is authenticated by a tour author' do
      tour = create(:tour)
      tour.update(published: false)
      create_list(:flat_page, 3)
      FlatPage.all.each { |flat_page| tour.flat_pages << flat_page }
      tour.flat_pages.first.update(tours: [tour])
      user = create(:user)
      user.update(super: false)
      user.tours << tour
      user.tour_sets = []
      signed_cookie(user)
      get :show, params: { tenant: Apartment::Tenant.current, id: tour.flat_pages.first.id }
      expect(response.status).to eq(200)
      expect(attributes[:title]).to eq(tour.flat_pages.first.title)
    end

    it 'returns a 200 response that is a stop when request is authenticated by a tenant admin' do
      tour = create(:tour)
      tour.update(published: false)
      create_list(:flat_page, 3)
      FlatPage.all.each { |flat_page| tour.flat_pages << flat_page }
      tour.flat_pages.first.update(tours: [tour])
      user = create(:user)
      user.update(super: false)
      user.tours = []
      user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
      signed_cookie(user)
      get :show, params: { tenant: Apartment::Tenant.current, id: tour.flat_pages.first.id }
      expect(response.status).to eq(200)
      expect(attributes[:title]).to eq(tour.flat_pages.first.title)
    end

    it 'returns a 200 response that is a stop when request is authenticated by a super user' do
      tour = create(:tour)
      tour.update(published: false)
      create_list(:flat_page, 3)
      FlatPage.all.each { |flat_page| tour.flat_pages << flat_page }
      tour.flat_pages.first.update(tours: [tour])
      user = create(:user)
      user.update(super: true)
      user.tours = []
      user.tour_sets = []
      signed_cookie(user)
      get :show, params: { tenant: Apartment::Tenant.current, id: tour.flat_pages.first.id }
      expect(response.status).to eq(200)
      expect(attributes[:title]).to eq(tour.flat_pages.first.title)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'return 401 when unauthenciated' do
          post :create, params: { data: { type: 'flat_pages', attributes: { title: 'Burrito FlatPage' } }, tenant: Apartment::Tenant.current }
          expect(response.status).to eq(401)
        end

      it 'return 401 when authenciated but not an admin for current tenant' do
        user = create(:user)
        user.update(super: false)
        user.tour_sets = []
        user.tours = []
        signed_cookie(user)
        post :create, params: { data: { type: 'flat_pages', attributes: { title: 'Burrito FlatPage' } }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(401)
      end

      it 'return 201 when authenciated but an admin for current tenant' do
        user = create(:user)
        user.update(super: false)
        user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
        signed_cookie(user)
        original_flat_page_count = FlatPage.count
        post :create, params: { data: { type: 'flat_pages', attributes: { title: 'Burrito FlatPage' } }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(201)
        expect(attributes[:title]).to eq('Burrito FlatPage')
        expect(FlatPage.count).to eq(original_flat_page_count + 1)
      end

      it 'return 201 when authenciated by super' do
        user = create(:user)
        user.tour_sets = []
        user.update(super: true)
        signed_cookie(user)
        original_flat_page_count = FlatPage.count
        post :create, params: { data: { type: 'flat_pages', attributes: { title: 'Taco FlatPage' } }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(201)
        expect(attributes[:title]).to eq('Taco FlatPage')
        expect(FlatPage.count).to eq(original_flat_page_count + 1)
      end

      it 'return 201 when authenciated by a tour author' do
        user = create(:user)
        user.tour_sets = []
        user.tours << Tour.last
        user.update(super: false)
        signed_cookie(user)
        original_flat_page_count = FlatPage.count
        post :create, params: { data: { type: 'flat_pages', attributes: { title: 'Elmyr' } }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(201)
        expect(attributes[:title]).to eq('Elmyr')
        expect(FlatPage.count).to eq(original_flat_page_count + 1)
      end

      it 'return 422 when missing title' do
        user = create(:user, super: true)
        signed_cookie(user)
        original_flat_page_count = FlatPage.count
        post :create, params: { data: { type: 'flat_pages', attributes: {} }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(422)
        expect(errors).to include('Title can\'t be blank')
        expect(FlatPage.count).to eq(original_flat_page_count)
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      it 'return 401 when unauthenciated' do
        tour = create(:tour_with_flat_pages)
        post :update, params: { id: tour.flat_pages.last.id, data: { type: 'flat_pages', attributes: { title: 'Burrito FlatPage' } }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(401)
      end

      it 'return 401 when authenciated but not an admin for current tenant' do
        tour = create(:tour_with_flat_pages, published: false)
        user = create(:user)
        user.update(super: false)
        user.tour_sets = []
        user.tours = []
        signed_cookie(user)
        post :update, params: { id: tour.flat_pages.first.id, data: { type: 'flat_pages', attributes: { title: 'Burrito FlatPage' } }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(401)
      end

      it 'return 200 and updated tour when authenciated but an admin for current tenant' do
        tour = create(:tour_with_flat_pages, published: false)
        user = create(:user)
        user.update(super: false)
        user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
        signed_cookie(user)
        original_flat_page_title = FlatPage.find(tour.flat_pages.last.id).title
        new_title = Faker::Name.unique.name
        post :update, params: { id: tour.flat_pages.first.id, data: { type: 'flat_pages', attributes: { title: new_title } }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(200)
        expect(attributes[:title]).not_to eq(original_flat_page_title)
        expect(attributes[:title]).to eq(new_title)
        expect(FlatPage.find(tour.flat_pages.first.id).title).to eq(new_title)
      end

      it 'return 200 and updated tour when authenciated by super' do
        tour = create(:tour_with_flat_pages)
        user = create(:user)
        user.tour_sets = []
        user.update(super: true)
        signed_cookie(user)
        original_flat_page_title = FlatPage.find(tour.flat_pages.last.id).title
        new_title = Faker::Name.unique.name
        post :update, params: { id: tour.flat_pages.last.id, data: { type: 'flat_pages', attributes: { title: new_title } }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(200)
        expect(attributes[:title]).not_to eq(original_flat_page_title)
        expect(attributes[:title]).to eq(new_title)
        expect(FlatPage.find(tour.flat_pages.last.id).title).to eq(new_title)
      end

      it 'return 200 and updated tour when authenciated by tour author' do
        tour = create(:tour_with_flat_pages)
        user = create(:user)
        user.update(super: false)
        user.tour_sets = []
        user.tours << tour
        signed_cookie(user)
        original_flat_page_title = FlatPage.find(tour.flat_pages.last.id).title
        new_title = Faker::Name.unique.name
        post :update, params: { id: tour.flat_pages.first.id, data: { type: 'flat_pages', attributes: { title: new_title } }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(200)
        expect(attributes[:title]).not_to eq(original_flat_page_title)
        expect(attributes[:title]).to eq(new_title)
        expect(FlatPage.find(tour.flat_pages.first.id).title).to eq(new_title)
      end

      it 'returns 422 when title in nil' do
        flat_page = create(:flat_page)
        user = create(:user, super: true)
        signed_cookie(user)
        post :update, params: { id: flat_page.id, data: { type: 'flat_pages', attributes: { title: nil } }, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(422)
        expect(errors).to include('Title can\'t be blank')
      end
    end

    # context 'with invalid params' do
    #   it 'renders a JSON response with errors for the tour' do
    #     tour = FlatPage.create! valid_attributes

    #     put :update, params: { id: tour.to_param, tour: invalid_attributes }
    #     expect(response).to have_http_status(:unprocessable_entity)
    #     expect(response.content_type).to eq('application/json')
    #   end
    # end
  end

  describe 'DELETE #destroy' do
    it 'return 401 when unauthenciated' do
      tour = create(:tour_with_flat_pages)
      post :destroy, params: { id: Tour.find(tour.id).flat_pages.first.id, tenant: Apartment::Tenant.current }
      expect(response.status).to eq(401)
    end

    it 'return 401 when authenciated but not an admin for current tenant' do
      tour = create(:tour_with_flat_pages)
      user = create(:user)
      user.update(super: false)
      user.tour_sets = []
      signed_cookie(user)
      post :destroy, params: { id: tour.flat_pages.first.id, tenant: Apartment::Tenant.current }
      expect(response.status).to eq(401)
    end

    it 'return 204 and one less tour when authenciated but an admin for current tenant' do
      tour = create(:tour_with_flat_pages)
      user = create(:user)
      user.update(super: false)
      user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
      signed_cookie(user)
      flat_page_count = FlatPage.count
      post :destroy, params: { id: tour.flat_pages.last.id, tenant: Apartment::Tenant.current }
      expect(response.status).to eq(204)
      expect(FlatPage.count).to eq(flat_page_count - 1)
    end

    it 'return 204 and one less tour when authenciated by super' do
      tour = create(:tour_with_flat_pages)
      user = create(:user)
      user.tour_sets = []
      user.update(super: true)
      signed_cookie(user)
      flat_page_count = FlatPage.count
      post :destroy, params: { id: tour.flat_pages.first.id, tenant: Apartment::Tenant.current }
      expect(response.status).to eq(204)
      expect(FlatPage.count).to eq(flat_page_count - 1)
    end

    it 'return 204 and one less tour when authenciated by tour author' do
      tour = create(:tour_with_flat_pages)
      user = create(:user)
      user.update(super: false)
      user.tour_sets = []
      user.tours << tour
      signed_cookie(user)
      new_title = Faker::Name.unique.name
      flat_page_count = FlatPage.count
      post :destroy, params: { id: tour.flat_pages.last.id, tenant: Apartment::Tenant.current }
      expect(response.status).to eq(204)
      expect(FlatPage.count).to eq(flat_page_count - 1)
    end
  end
end
