# frozen_string_literal: true

require 'rails_helper'
require 'digest/md5'

RSpec.describe 'V3::Media', type: :request do
  let!(:medium) { create(:medium) }
  let!(:tour) { create(:tour, media: [medium], published: true, theme: create(:theme)) }
  let(:medium_id) { medium.id }
  let!(:user) { create(:user) }
  let!(:login) { create(:login, user: user) }
  let(:headers) { { Authorization: "Bearer #{login.oauth2_token}" } }


  describe 'GET /media' do
    it 'media has all versions' do
      get "/#{Apartment::Tenant.current}/media/#{medium_id}"
      expect(response).to have_http_status(200)
      expect(attributes['original_image']['url']).to eq("/uploads/#{Apartment::Tenant.current}/300x300.png")
      expect(attributes['desktop']).to eq("/uploads/#{Apartment::Tenant.current}/desktop_300x300.png")
      expect(attributes['tablet']).to eq("/uploads/#{Apartment::Tenant.current}/tablet_300x300.png")
      expect(attributes['mobile']).to eq("/uploads/#{Apartment::Tenant.current}/mobile_list_thumb_300x300.png")
      # FIXME use a more stable image for comparing the hash
      expect(Digest::MD5.hexdigest(File.read("#{Rails.root}/public#{attributes['original_image']['url']}"))).to eq('cd98598f356f0afa5cc6d3002627b719')
    end
  end

  describe 'POST /media with local file handel' do
    let(:valid_attributes) do
      factory_to_json_api(
        FactoryBot.build(:medium)
      )
    end

    before {
      valid_attributes[:data][:attributes]['original_image'] = Rack::Test::UploadedFile.new(Rails.root.join('spec/factories/images/otblogo.png'), 'image/png')
      User.last.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
      post "/#{Apartment::Tenant.current}/media", params: valid_attributes, headers: { Authorization: "Bearer #{User.last.login.oauth2_token}" }
    }

    it 'uploads from local file handel' do
      expect(response).to have_http_status(201)
      expect(attributes['original_image']['url']).to eq("/uploads/#{Apartment::Tenant.current}/otblogo.png")
      expect(Digest::MD5.hexdigest(File.read("#{Rails.root}/public#{attributes['original_image']['url']}"))).to eq('4cb687e488c9ade8effc63817bb92c48')
    end
  end

  describe 'POST /media' do
    let(:valid_attributes) do
      factory_to_json_api(FactoryBot.build(:medium, video: 'https://youtu.be/F9ULbmCvmxY'))
    end

    before { Apartment::Tenant.switch! TourSet.find(TourSet.pluck(:id).sample).subdir }
    before { User.last.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current) }

    before { post "/#{Apartment::Tenant.current}/media", params: valid_attributes, headers: { Authorization: "Bearer #{User.last.login.oauth2_token}" } }

    context 'create with YouTube share url' do
      it 'creates image from YouTube' do
        expect(User.last.current_tenant_admin?).to eq(true)
        expect(response).to have_http_status(201)
        expect(attributes['original_image']['url']).to eq("/uploads/#{Apartment::Tenant.current}/F9ULbmCvmxY.jpg")
      end
    end
  end

  describe 'POST /media invalid' do
    let(:valid_attributes) do
      factory_to_json_api(FactoryBot.build(:medium, video: 'https://youtu.be/F9ULbmCvmxY'))
    end

    before {
      invalid_attributes = valid_attributes
      invalid_attributes[:data][:attributes].delete('video')
      post "/#{Apartment::Tenant.current}/media", params: invalid_attributes, headers: { Authorization: "Bearer #{User.last.login.oauth2_token}" }
    }
    context 'create invaild is unprocessable' do
      it 'return 422' do
        expect(response).to have_http_status(422)
      end
    end
  end

  describe 'POST /media with base64' do

    context 'Upload image as base64 string' do
      let(:base64_request) do
        factory_to_json_api(FactoryBot.build(:medium, remote_original_image_url: nil))
      end

      before {
        base64_request[:data][:attributes][:original_image] = File.read('spec/factories/base64_image.txt')
        post "/#{Apartment::Tenant.current}/media", params: base64_request, headers: headers
      }

      it 'returns created' do
        expect(response).to have_http_status(201)
      end
    end
  end

  describe 'POST /media with YouTube url' do
    let(:valid_attributes) do
      factory_to_json_api(FactoryBot.build(:medium, video: 'https://www.youtube.com/watch?v=F9ULbmCvmxY', tours: [tour]))
    end

    before { post "/#{Apartment::Tenant.current}/media", params: valid_attributes, headers: headers }

    it 'creates image from YouTube url' do
      expect(attributes['original_image']['url']).to eq("/uploads/#{Apartment::Tenant.current}/F9ULbmCvmxY.jpg")
      # expect(Digest::MD5.hexdigest(File.read("#{Rails.root}/public#{attributes['original_image']['url']}"))).to eq('e46304e85b7be7fd9183b4384b2e447f')
    end
  end

  describe 'POST /media with YouTube id' do
    let(:valid_attributes) do
      factory_to_json_api(FactoryBot.build(:medium, video: 'F9ULbmCvmxY'))
    end

    before { post "/#{Apartment::Tenant.current}/media", params: valid_attributes, headers: headers }

    it 'creates image from YouTube id' do
      expect(attributes['original_image']['url']).to eq("/uploads/#{Apartment::Tenant.current}/F9ULbmCvmxY.jpg")
      expect(Digest::MD5.hexdigest(File.read("#{Rails.root}/public#{attributes['original_image']['url']}"))).to eq('e2b22110134014b8bfcd2f05ebffdffd')
    end
  end

  describe 'POST /media with YouTube embed code' do
    let(:valid_attributes) do
      factory_to_json_api(
        FactoryBot.build(
          :medium,
          video: '<iframe width="560" height="315" src="https://www.youtube.com/embed/F9ULbmCvmxY" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>',
          original_image: nil
        )
      )
    end

    before {
      post "/#{Apartment::Tenant.current}/media", params: valid_attributes, headers: headers
    }

    it 'creates image from YouTube embed code' do
      expect(attributes['original_image']['url']).to eq("/uploads/#{Apartment::Tenant.current}/F9ULbmCvmxY.jpg")
      expect(MIME::Types.type_for("/public#{attributes['original_image']['url']}").first.content_type).to eq('image/jpeg')
    end
  end

  describe 'POST /media with Vimeo url' do
    let(:valid_attributes) do
      factory_to_json_api(FactoryBot.build(:medium, video: 'https://vimeo.com/310645255'))
    end

    before { post "/#{Apartment::Tenant.current}/media", params: valid_attributes, headers: headers }

    it 'creates image from Vimeo url' do
      expect(attributes['original_image']['url']).to eq("/uploads/#{Apartment::Tenant.current}/310645255.jpg")
      # expect(Digest::MD5.hexdigest(File.read("#{Rails.root}/public#{attributes['original_image']['url']}"))).to eq('c1d74a506d83a46144f7fd089bedacbb')
    end
  end

  describe 'POST /media with Vimeo id' do
    let(:valid_attributes) do
      factory_to_json_api(FactoryBot.build(:medium, video: '310645255'))
    end

    before { post "/#{Apartment::Tenant.current}/media", params: valid_attributes, headers: headers }

    # FIXME: For some reason, this test always fails on Travis ¯\_(ツ)_/¯
    it 'creates image from Vimeo id' do
      expect(attributes['original_image']['url']).to eq("/uploads/#{Apartment::Tenant.current}/310645255.jpg")
    end
  end

  describe 'POST /media with Vimeo iframe code' do
    let(:valid_attributes) do
      factory_to_json_api(FactoryBot.build(:medium, video: '<iframe src="https://player.vimeo.com/video/310645255" width="640" height="360" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe><p><a href="https://vimeo.com/310645255">Migos - What The Price</a> from <a href="https://vimeo.com/cr8tiverow">CR8TIVE ROW</a> on <a href="https://vimeo.com">Vimeo</a>.</p>'))
    end

    before {
      post "/#{Apartment::Tenant.current}/media", params: valid_attributes, headers: headers
    }

    it 'creates image from Vimeo embed iframe' do
      expect(attributes['original_image']['url']).to eq("/uploads/#{Apartment::Tenant.current}/310645255.jpg")
    end
  end

  describe 'PUT /media/<id>' do
    let(:valid_attributes) do
      factory_to_json_api(FactoryBot.build(:medium, remote_original_image_url: nil))
    end

    context 'update with valid data' do
      before {
        valid_attributes[:data][:attributes]['original_image'] = Rack::Test::UploadedFile.new(Rails.root.join('spec/factories/test.jpg'), 'image/jpg')
        valid_attributes[:data][:attributes]['id'] = Medium.first.id
        put "/#{Apartment::Tenant.current}/media/#{Medium.first.id}", params: valid_attributes, headers: { Authorization: "Bearer #{User.last.login.oauth2_token}" }
      }

      it 'updates image' do
        expect(response).to have_http_status(200)
      end
    end

    context 'update unauthenticated' do
      before {
        valid_attributes[:data][:attributes]['id'] = Medium.first.id
        put "/#{Apartment::Tenant.current}/media/#{Medium.first.id}", params: valid_attributes
      }

      it 'updates image' do
        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'DELETE /media/<id>' do
    context 'delete while authenticated' do
      before {
        delete "/#{Apartment::Tenant.current}/media/#{Medium.first.id}", headers: { Authorization: "Bearer #{User.last.login.oauth2_token}" }
      }

      it 'deletes midum' do
        expect(response).to have_http_status(204)
      end
    end

    context 'delte unauthenticated' do
      before {
        delete "/#{Apartment::Tenant.current}/media/#{Medium.first.id}"
      }

      it 'is unauthorized' do
        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'GET /media' do
    let!(:theme) { create(:theme) }
    let!(:stop) { create_list(:stop_with_media, 1) }
    let(:stop_id) { stop.first.id }
    let!(:tour) { create_list(:tour_with_media, 1, theme: theme) }
    let(:tour_id) { tour.first.id }

    # The stop makes 5 media, the tour makes 2, plus the 1 created at the begining
    # makes a total of 8.

    context 'get all media' do
      before { get "/#{Apartment::Tenant.current}/media" }

      it 'has X media records' do
        expect(json.size).to eq(8)
      end
    end

    context 'get all media not associated with specific stop' do
      let(:valid_attributes) do
        factory_to_json_api(FactoryBot.build(:medium, stop_ids: stop_id))
      end

      before { get "/#{Apartment::Tenant.current}/media?stop_id=#{stop_id}" }

      it 'gets media not associated with stop' do
        expect(json.size).to eq(3)
      end
    end

    context 'get all media not associated with specific tour' do
      before { get "/#{Apartment::Tenant.current}/media?tour_id=#{tour_id}" }

      it 'gets media not associated with tour' do
        expect(json.size).to eq(6)
      end
    end
  end

  describe 'Get unplubished Media' do
    let(:un_pub_tour_medium) { create(:medium) }
    let(:un_pub_stop_medium) { create(:medium) }
    let(:un_pub_stop) { create(:stop, media: [un_pub_stop_medium]) }
    let(:un_pub_tour) { create(:tour, media: [un_pub_tour_medium], published: false, stops: [un_pub_stop], theme: create(:theme)) }
    let(:un_pub_medium_id) { medium.id }

    context 'Request unpublished tour media' do
      before { get "/#{Apartment::Tenant.current}/media/#{un_pub_tour_medium.id}" }

      it 'returns unauthorized' do
        expect(response).to have_http_status(401)
      end
    end

    context 'Request unpublished stop media' do
      before { get "/#{Apartment::Tenant.current}/media/#{un_pub_stop_medium.id}" }

      it 'returns unauthorized' do
        expect(response).to have_http_status(401)
      end
    end
  end
end
