require "rails_helper"

RSpec.describe V4::Admin::CrudController, type: :controller do
  describe "PUT #create" do
    it "returns 401 when unauthenticated" do
      post :create, params: { tenant: TourSet.last.subdir, data: { model: "tour", title: Faker::Book.title } }
      expect(response.status).to eq(401)
    end
  end

  describe "put #update" do
    it "returns 401 when unauthenticated" do
      post :create, params: { tenant: TourSet.last.subdir, data: { model: "tour", title: Faker::Book.title } }
      expect(response.status).to eq(401)
    end

    it "returns 204 and updates tour title when authenticated" do
        tour = create(:tour, published: false)
        user = create(:user)
        user.update(super: false)
        user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
        signed_cookie(user)
        new_title = Faker::Name.unique.name
        request_body = {
          model: 'tour',
          attribute: "title",
          value: new_title
        }
        expect(Tour.find(tour.id).title).not_to eq(new_title)
        put :update, params: { id: tour.id, **request_body, tenant: Apartment::Tenant.current }
        expect(response.status).to eq(204)
        expect(Tour.find(tour.id).title).to eq(new_title)
    end

    it "adds a belongs to association" do
      tour = create(:tour)
      new_theme = create(:theme)
      user = create(:user, super: true)
      signed_cookie(user)
      expect(tour.theme).not_to eq(new_theme)
      tour.update(theme: new_theme)
      request_body = {
        model: "tour",
        attribute: "theme",
        value: new_theme.id.to_s,
        related_model: "theme",
        relation_type: "belongs_to"
      }
      put :update, params: { id: tour.id, **request_body, tenant: Apartment::Tenant.current }
      expect(tour.theme).to eq(new_theme)
    end
  end
end
