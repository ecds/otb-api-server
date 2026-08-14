# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(V4::Admin::CrudController, type: :controller) do
  describe 'POST #create' do
    it 'returns 401 when unauthenticated' do
      post :create, params: { tenant: TourSet.last.subdir, data: { model: 'tour', title: Faker::Book.title } }
      expect(response.status).to(eq(401))
    end

    it 'uploads a file' do
      user = create(:user, super: true)
      signed_cookie(user)
      file = Rack::Test::UploadedFile.new(
        Rails.root.join('spec/factories/images/0.jpg'),
        'image/jpeg',
      )
      post :create, params: { tenant: TourSet.first.subdir, model: 'medium', medium: { file: file, filename: '0.jpg' } }
      medium = Medium.find(v4_json[:id])
      expect(medium.file).to(be_attached)
      expect(response).to(have_http_status(:created))
    end

    it 'adds a medium to a tour' do
      user = create(:user, super: true)
      signed_cookie(user)
      tour = create(:tour)
      medium = create(:medium)
      expect(medium.file.attached?)
      post :create, params: { tenant: Apartment::Tenant.current, model: 'tour_medium', tour_medium: { tour_id: tour.id, medium_id: medium.id, position: 2 } }
      expect(response).to(have_http_status(:created))
    end

    it 'uploads a map icon' do
      user = create(:user, super: true)
      signed_cookie(user)
      file = Rack::Test::UploadedFile.new(
        Rails.root.join('spec/factories/images/map_icon.jpg'), 'image/jpeg'
      )
      post :create,
        params: { tenant: TourSet.second.subdir, model: 'map_icon', map_icon: { file:, filename: 'map_icon.jpg' } }
      expect(response).to(have_http_status(:created))
    end

    it 'rejects a map icon that is to big' do
      user = create(:user, super: true)
      signed_cookie(user)
      file = Rack::Test::UploadedFile.new(
        Rails.root.join('spec/factories/images/map_icon_too_big.jpg'), 'image/jpeg'
      )
      post :create,
        params: { tenant: TourSet.second.subdir, model: 'map_icon', map_icon: { file:, filename: 'map_icon.jpg' } }
      expect(response).to(have_http_status(:unprocessable_entity))
      expect(v4_json[:errors].first[:detail]).to(eq('File Icons should be no bigger that 80 by 80 pixels'))
    end

    it 'creates a stop with default lat/lon based on request location' do
      user = create(:user, super: true)
      signed_cookie(user)
      request.remote_ip = Faker::Internet.ip_v4_address
      post :create, params: { tenant: TourSet.last.subdir, model: 'stop', stop: { title: Faker::Movies::HitchhikersGuideToTheGalaxy.planet } }
      expect(v4_json[:lat]).not_to(be_nil)
      expect(v4_json[:lng]).not_to(be_nil)
    end

    it 'allows super to create record in public tenant' do
      user = create(:user, super: true)
      new_user = create(:user, super: false)
      new_tenant = create(:tour_set)
      signed_cookie(user)
      post :create,
        params: {
          tenant: 'public',
          model: 'tour_set_admin',
          tour_set_admin: { user_id: new_user.id, tour_set_id: new_tenant.id },
        }
      expect(response).to(have_http_status(:created))
      expect(new_user.tour_sets).to(include(new_tenant))
    end

    it 'uploads a voice over mp3' do
      user = create(:user, super: true)
      signed_cookie(user)
      file = Rack::Test::UploadedFile.new(
        Rails.root.join('spec/fixtures/audio/sample.mp3'),
        'audio/mpeg',
      )
      Apartment::Tenant.switch!(TourSet.first.subdir)
      tour = create(:tour)
      post :create, params: { tenant: TourSet.first.subdir, model: 'voice_over', voice_over: { file: file, tour_id: tour.id } }
      voice_over = VoiceOver.find(v4_json[:id])
      expect(voice_over.file).to(be_attached)
      expect(v4_json[:filename]).to(eq('sample.mp3'))
      expect(response).to(have_http_status(:created))
    end

    it 'uploads a voice over m4a' do
      user = create(:user, super: true)
      signed_cookie(user)
      file = Rack::Test::UploadedFile.new(
        Rails.root.join('spec/fixtures/audio/sample.m4a'),
        'audio/mp4',
      )
      Apartment::Tenant.switch!(TourSet.first.subdir)
      stop = create(:stop)
      post :create, params: { tenant: TourSet.first.subdir, model: 'voice_over', voice_over: { file: file, stop_id: stop.id } }
      voice_over = VoiceOver.find(v4_json[:id])
      expect(voice_over.file).to(be_attached)
      expect(response).to(have_http_status(:created))
    end

    it 'uploads a voice over audio/x-m4a' do
      user = create(:user, super: true)
      signed_cookie(user)
      file = Rack::Test::UploadedFile.new(
        Rails.root.join('spec/fixtures/audio/sample.m4a'),
        'audio/x-m4a',
      )
      Apartment::Tenant.switch!(TourSet.first.subdir)
      stop = create(:stop)
      post :create, params: { tenant: TourSet.first.subdir, model: 'voice_over', voice_over: { file: file, stop_id: stop.id } }
      voice_over = VoiceOver.find(v4_json[:id])
      expect(voice_over.file).to(be_attached)
      expect(response).to(have_http_status(:created))
    end

    it 'rejects a voice over wav' do
      user = create(:user, super: true)
      signed_cookie(user)
      file = Rack::Test::UploadedFile.new(
        Rails.root.join('spec/fixtures/audio/sample.wav'),
        'audio/wave',
      )
      Apartment::Tenant.switch!(TourSet.first.subdir)
      tour = create(:tour)
      post :create, params: { tenant: TourSet.first.subdir, model: 'voice_over', voice_over: { file: file, tour_id: tour.id } }
      expect(v4_json[:errors].first[:detail]).to(eq('File must be an MP3 or M4A audio file'))
      expect(response).to(have_http_status(:unprocessable_entity))
    end

    it 'rejects a voice over with no tour or stop' do
      user = create(:user, super: true)
      signed_cookie(user)
      file = Rack::Test::UploadedFile.new(
        Rails.root.join('spec/fixtures/audio/sample.mp3'),
        'audio/mpeg',
      )
      Apartment::Tenant.switch!(TourSet.first.subdir)
      post :create, params: { tenant: TourSet.first.subdir, model: 'voice_over', voice_over: { file: file } }
      expect(v4_json[:errors].first[:detail]).to(eq('must belong to exactly one of tour or stop'))
      expect(response).to(have_http_status(:unprocessable_entity))
    end
  end

  describe 'PUT #update' do
    it 'returns 401 when unauthenticated' do
      post :create, params: { tenant: TourSet.last.subdir, data: { model: 'tour', title: Faker::Book.title } }
      expect(response.status).to(eq(401))
    end

    it 'returns 200 and updates tour title when authenticated' do
      tour = create(:tour, published: false)
      user = create(:user)
      user.update(super: false)
      user.tour_sets << TourSet.find_by(subdir: Apartment::Tenant.current)
      signed_cookie(user)
      new_title = Faker::Name.unique.name
      request_body = {
        model: 'tour',
        tour: { title: new_title },
      }
      expect(Tour.find(tour.id).title).not_to(eq(new_title))
      put :update, params: { id: tour.id, **request_body, tenant: Apartment::Tenant.current }
      expect(response.status).to(eq(200))
      expect(Tour.find(tour.id).title).to(eq(new_title))
    end

    it 'adds a belongs to association' do
      tour = create(:tour)
      new_theme = create(:theme)
      user = create(:user, super: true)
      signed_cookie(user)
      expect(tour.theme).not_to(eq(new_theme))
      tour.update(theme: new_theme)
      request_body = {
        model: 'tour',
        attribute: 'theme',
        value: new_theme.id.to_s,
        related_model: 'theme',
        relation_type: 'belongs_to',
      }
      put :update, params: { id: tour.id, **request_body, tenant: Apartment::Tenant.current }
      expect(tour.theme).to(eq(new_theme))
    end

    it 'adds icon to stop' do
      icon = create(:map_icon)
      stop = create(:stop, map_icon: nil)
      user = create(:user, super: true)
      signed_cookie(user)
      request_body = {
        id: stop.id,
        tenant: Apartment::Tenant.current,
        model: 'stop',
        attribute: 'map_icon',
        related_model: 'map_icon',
        related_type: 'belongs_to',
        value: icon.id,
      }
      put :update, params: { id: stop.id, tenant: Apartment::Tenant.current, **request_body }
      expect(v4_json[:map_icon]).to(include(icon.filename))
    end

    it 'uploads and replaces file' do
      user = create(:user, super: true)
      signed_cookie(user)
      medium = create(
        :medium,
        base_sixty_four: nil,
        file: fixture_file_upload(Rails.root.join('spec/factories/images/atl.png'), 'image/png'),
      )
      expect(medium.file.attached?)
      original_files = medium.search_data[:files]
      original_checksum = medium.file.blob.checksum
      file = Rack::Test::UploadedFile.new(
        Rails.root.join('spec/factories/images/0.jpg'),
        'image/jpeg',
      )
      request_body = {
        id: medium.id,
        tenant: Apartment::Tenant.current,
        model: 'medium',
        medium: { file: },
      }
      put :update, params: request_body
      expect(v4_json[:files]).not_to(eq(original_files))
      medium.reload
      expect(medium.file).to(be_attached)
      expect(medium.file.blob.checksum).not_to(eq(original_checksum))
    end

    it 'adds a logo to a tour set' do
      user = create(:user, super: true)
      tour_set = TourSet.second
      user.tour_sets << tour_set
      expect(tour_set.logo_url).to(be_nil)
      Apartment::Tenant.switch!('public')
      signed_cookie(user)
      file = Rack::Test::UploadedFile.new(
        Rails.root.join('spec/factories/images/0.jpg'),
        'image/jpeg',
      )
      request_body = {
        id: tour_set.id,
        tenant: 'public',
        model: 'tour_set',
        tour_set: { logo: file },
      }
      put :update, params: request_body
      tour_set.reload
      expect(v4_json[:logo_url]).not_to(be_nil)
      expect(tour_set.logo).to(be_attached)
    end

    it 'cannot rename a tour with a name that already exists' do
      user = create(:user, super: true)
      tour1 = create(:tour)
      tour2 = create(:tour)
      signed_cookie(user)
      request_body = {
        id: tour2.id,
        tenant: 'public',
        model: 'tour',
        tour: { title: tour1.title },
      }
      put :update, params: request_body
      expect(v4_json[:errors].first[:detail]).to(eq('Title has already been taken'))
      expect(response.status).to(eq(422))
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested record' do
      tour = create(:tour_with_stops)
      user = create(:user, super: true)
      signed_cookie(user)
      expect do
        delete(:destroy, params: { id: tour.tour_stops.first.id, model: 'tour_stop', tenant: Apartment::Tenant.current })
      end.to(change(TourStop, :count).by(-1))
    end

    it 'responds unauthorized when unauthenticated' do
      delete :destroy, params: { id: Tour.first.id, model: 'tour', tenant: Apartment::Tenant.current }
      expect(response.status).to(eq(401))
    end
  end
end
