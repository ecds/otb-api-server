# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('V4::Admin::Crud', type: :request) do
  describe 'POST /:tenant/v4/admin/crud' do
    let(:file) do
      Rack::Test::UploadedFile.new(
        Rails.root.join('spec', 'factories', 'images', '0.jpg'),
        'image/jpeg',
      )
    end
    context 'with valid file' do
      it 'uploads the file' do
        post "/#{Apartment::Tenant.current}/v4/admin/crud", params: { model: 'medium', medium: { file:, filename: '0.jpg' } }
        expect(response).to(have_http_status(:unauthorized))
      end
    end
  end
end
