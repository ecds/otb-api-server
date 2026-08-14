# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('V4::Admin::Services', type: :request) do
  describe 'GET /:tenant/v4/admin/resolve_url' do
    context 'with valid url' do
      it 'returns resolved url' do
        stub_request(:head, 'https://skfb.ly/owuDQ')
          .to_return(status: 301, headers: { 'Location' => 'https://sketchfab.com:443/s/owuDQ' })
        stub_request(:head, 'https://sketchfab.com:443/s/owuDQ')
          .to_return(status: 301, headers: { 'Location' => 'https://sketchfab.com/3d-models/apis-bull-statuette-f6fd7079d7364f8399af1c66b1e53730' })
        stub_request(:head, 'https://sketchfab.com/3d-models/apis-bull-statuette-f6fd7079d7364f8399af1c66b1e53730')
          .to_return(status: 200)

        get "/#{Apartment::Tenant.current}/v4/admin/resolve_url", params: { url: 'https://skfb.ly/owuDQ' }
        expect(response).to(have_http_status(:ok))
        expect(all_json[:resolved_url]).to(eq('https://sketchfab.com/3d-models/apis-bull-statuette-f6fd7079d7364f8399af1c66b1e53730'))
      end
    end

    context 'without a url param' do
      it 'returns 422' do
        get "/#{Apartment::Tenant.current}/v4/admin/resolve_url"
        expect(response).to(have_http_status(:unprocessable_entity))
      end
    end
  end
end
