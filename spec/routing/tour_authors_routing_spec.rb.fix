require "rails_helper"

RSpec.describe TourAuthorsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/tour_authors").to route_to("tour_authors#index")
    end

    it "routes to #show" do
      expect(get: "/tour_authors/1").to route_to("tour_authors#show", id: "1")
    end


    it "routes to #create" do
      expect(post: "/tour_authors").to route_to("tour_authors#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/tour_authors/1").to route_to("tour_authors#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/tour_authors/1").to route_to("tour_authors#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/tour_authors/1").to route_to("tour_authors#destroy", id: "1")
    end
  end
end
