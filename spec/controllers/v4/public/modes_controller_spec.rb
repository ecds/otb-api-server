require "rails_helper"

RSpec.describe V4::Public::ModesController, type: :controller do
  describe "PUT #create" do
    it "gets the list of modes" do
      get :index, params: { tenant: Apartment::Tenant.current }
      expect(v4_json.count).to eq(4)
    end
  end
end
