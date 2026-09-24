# frozen_string_literal: true

require 'rails_helper'

# Full CRUD behaviour (including authenticated paths) is covered in
# spec/controllers/v4/admin/access_requests_controller_spec.rb.
# These request specs verify the route exists and rejects unauthenticated access.

RSpec.describe('V4::Admin::AccessRequests', type: :request) do
  let(:tour_set) { create(:tour_set) }

  describe 'GET /:tenant/v4/admin/access_requests' do
    it 'returns 401 when unauthenticated' do
      get "/#{tour_set.subdir}/v4/admin/access_requests"
      expect(response).to(have_http_status(:unauthorized))
    end
  end

  describe 'POST /:tenant/v4/admin/access_requests' do
    it 'returns 401 when unauthenticated' do
      post "/#{tour_set.subdir}/v4/admin/access_requests"
      expect(response).to(have_http_status(:unauthorized))
    end
  end
end
