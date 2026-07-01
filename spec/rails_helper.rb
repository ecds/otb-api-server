# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require(File.expand_path('../config/environment', __dir__))
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'
require 'database_cleaner'
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }
# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework(:rspec)
    with.library(:rails)
  end
end

def delete_test_indices
  Searchkick.client.indices.get(index: 'otb_*_test').keys.each_slice(10) do |batch|
    Searchkick.client.indices.delete(index: batch.join(','))
  end
end

def reset_test_db!
  # Drop every Apartment tenant schema so factory-created schemas from a
  # previous run (or a force-killed run) don't accumulate or conflict.
  Apartment::Tenant.reset
  TourSet.pluck(:subdir).each do |subdir|
    Apartment::Tenant.drop(subdir)
  rescue StandardError
    nil
  end

  # Wipe all public-schema tables. Order matters for FK constraints.
  tables = [
    'active_storage_attachments',
    'active_storage_blobs',
    'active_storage_variant_records',
    'tour_set_admins',
    'access_requests',
    'tour_authors',
    'logins',
    'tokens',
    'tour_sets',
    'users',
    'modes',
    'roles',
    'themes',
  ]
  tables.each do |t|
    ActiveRecord::Base.connection.execute("TRUNCATE #{t} RESTART IDENTITY CASCADE")
  rescue
    nil
  end
end

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [Rails.root.join('spec/fixtures').to_s]

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  if ENV['DB_ADAPTER'] == 'postgresql'
    # config.use_transactional_fixtures = true
  end

  config.include(RequestSpecHelper, type: :request)
  config.include(RequestSpecHelper, type: :controller)
  config.include(SignedCookieHelper, type: :request)
  config.include(SignedCookieHelper, type: :controller)
  config.include(FactoryBot::Syntax::Methods)
  # start by truncating all the tables but then use the faster transaction strategy the rest of the time.
  config.before(:suite) do
    # Start from a clean slate every run so re-seeding is safe and
    # schemas from a previous (possibly force-killed) run don't linger.
    reset_test_db!
    delete_test_indices
    Rails.application.routes.default_url_options = { host: 'www.example.com', protocol: 'https' }
    ActiveStorage::Current.url_options = { protocol: 'https', host: 'example.com', port: 443 }
    load Rails.root + 'db/seeds.rb'
  end

  # config.use_transactional_fixtures = true

  # start the transaction strategy as examples are run

  config.before do
    # MiniMagick.configure do |config|
    #   config.validate_on_create = false
    # end
    # Start transaction for this test
    # DatabaseCleaner.start
    # Switch into the default tenant
    Apartment::Tenant.switch!(TourSet.find(TourSet.pluck(:id).sample).subdir)
    # Set the host for ActiveStorage urls
    ActiveStorage::Current.url_options = { host: 'http://test.host' }

    # request.env["ipinfo"] = { city: Faker::Address.city, county: Faker::Address.country_code }

    # Stub network requests
    stub_request(:get, 'https://placehold.it/300x300.png_1000x1000')
      .to_return(body: File.open(Rails.root + 'spec/factories/images/0.jpg'), status: 200)

    # Vimeo — matches any video ID
    stub_request(:get, %r{https://vimeo\.com/api/oembed\.json\?url=https://vimeo\.com/video/\d+})
      .to_return(
        status: 200,
        body: '{"title": "CycloramaBattleSites.org Stop 2", "description": "A stub description", "thumbnail_url": "https://placehold.it/300x300.png", "thumbnail_width": 100, "thumbnail_height": 100}',
        headers: { 'content-type' => 'application/json' },
      )

    stub_request(:get, 'https://img.youtube.com/vi/F9ULbmCvmxY/0.jpg')
      .to_return(body: File.open(Rails.root + 'spec/factories/images/0.jpg'), status: 200)

    stub_request(:get, %r{http://test\.host/rails/active_storage/.*})
      .to_return(body: File.open(Rails.root + 'spec/factories/images/atl.png'), status: 200)

    # YouTube — valid video
    stub_request(:get, 'https://www.googleapis.com/youtube/v3/videos?id=F9ULbmCvmxY&key=AIzaSyAafrj3VvNLJNXeW5-NNCVwY5cdB06p1_s&part=snippet')
      .to_return(
        status: 200,
        body: '{"items": [{"id": "F9ULbmCvmxY", "snippet": {"title": "Goodie Mob - Black Ice (Sky High) ft. OutKast", "description": "Music video by Goodie Mob feat. OutKast performing Black Ice (Sky High). (C) 1998 LaFace Records LLC"}}]}',
        headers: { 'content-type' => 'application/json' },
      )

    # YouTube — not found
    stub_request(:get, 'https://www.googleapis.com/youtube/v3/videos?id=CvmxYF9ULbm&key=AIzaSyAafrj3VvNLJNXeW5-NNCVwY5cdB06p1_s&part=snippet')
      .to_return(
        status: 200,
        body: '{"kind": "youtube#videoListResponse", "items": [], "pageInfo": {"totalResults": 0, "resultsPerPage": 0}}',
        headers: { 'content-type' => 'application/json' },
      )

    # SoundCloud oembed — matches any track URL (HTTParty sorts params alphabetically)
    stub_request(:get, %r{https://soundcloud\.com/oembed})
      .to_return(
        status: 200,
        body: '{"title": "A SoundCloud Track", "thumbnail_url": "https://i1.sndcdn.com/artworks-stub-0-t500x500.jpg"}',
        headers: { 'Content-Type' => 'application/json' },
      )

    # SoundCloud thumbnail image
    stub_request(:get, %r{https://i1\.sndcdn\.com/artworks-.*\.jpg})
      .to_return(body: File.open(Rails.root + 'spec/factories/images/0.jpg'), status: 200)

    # Sketchfab embed page — matches any model ID
    stub_request(:get, %r{https://sketchfab\.com/models/.+/embed})
      .to_return(
        status: 200,
        body: '<html><head><meta property="og:title" content="A Sketchfab Model"><meta property="og:image" content="https://media.sketchfab.com/models/4b570878a3cc4ca786af824a03ada414/thumbnails/d8899e68c4a7435bbe229764bf4c2f57/fd4348dc5c7f48eea5c0d0b8ef376f8b.jpeg"></head><body></body></html>',
        headers: { 'Content-Type' => 'text/html' },
      )

    # Sketchfab thumbnail image
    stub_request(:get, %r{https://media\.sketchfab\.com/.*\.jpe?g})
      .to_return(body: File.open(Rails.root + 'spec/factories/images/0.jpg'), status: 200)

    # Generic iframe from unknown origin.
    stub_request(:get, 'https://3d-api.si.edu/voyager/3d_package:a1651b35')
      .to_return(
        status: 200,
        body: '<html><head><title>A Model</title></head><body></html>',
        headers: { 'Content-Type' => 'text/html' },
      )

    # MorphoSource IIIF manifest
    stub_request(:get, %r{https://www\.morphosource\.org/manifests/.*\.json})
      .to_return(
        status: 200,
        body: '{"label":{"@none":["Fragment [Mesh] [StrLight]"]},"summary":{"@none":["Italic terra sigillata fragment"]}}',
        headers: { 'Content-Type' => 'application/json' },
      )

    # Matterport model
    stub_request(:get, 'https://my.matterport.com/show/?m=matterport_id')
      .to_return(
        status: 200,
        body: '<html><head><meta property="og:title" content="A Matterport Model"><meta property="og:image" content="https://my.matterport.com/api/v2/player/models/matterport_id/thumb/"></head><body></body></html>',
        headers: { 'Content-Type' => 'text/html' },
      )

    # Matterport thumbnail image
    stub_request(:get, %r{https://my\.matterport\.com/.*\/thumb})
      .to_return(body: File.open(Rails.root + 'spec/factories/images/0.jpg'), status: 200)

    stub_request(:get, %r{http://127\.0\.0\.1:.*/json/version}).to_return(body: '{}', status: 200)

    stub_request(:get, %r{http.*://maps\.googleapis\.com/maps/api/.*BICYCLING.*})
      .to_return(body: File.read(Rails.root + 'spec/factories/distance_matrix.json'), status: 200, headers: { 'Content-Type': 'application/json' })

    stub_request(:get, %r{http.*://maps\.googleapis\.com/maps/api/.*TRANSIT.*})
      .to_return(body: File.read(Rails.root + 'spec/factories/distance_matrix2.json'), status: 200, headers: { 'Content-Type': 'application/json' })

    stub_request(:get, %r{http.*://maps\.googleapis\.com/maps/api/.*WALKING.*})
      .to_return(body: File.read(Rails.root + 'spec/factories/distance_matrix_zero.json'), status: 200, headers: { 'Content-Type': 'application/json' })

    stub_request(:get, %r{http.*://maps\.googleapis\.com/maps/api/.*DRIVING.*})
      .to_return(body: '{"status": "INVALID_REQUEST"}', status: 200, headers: { 'Content-Type': 'application/json' })

    stub_request(:get, 'http://og.ecds.io')
      .to_return(
        status: 200,
        body: '{"stops": ["Open Geographies"], "bounds": {"east": -83.8150232, "west": -83.2818954, "south": 32.6648851, "north": 33.8113142}}',
        headers: { 'Content-Type' => 'application/json' },
      )

    stub_request(:get, %r{http.*://ipinfo\.io/.*/geo.*})
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent' => 'Ruby',
        },
      )
      .to_return(status: 200, headers: {}, body: ip_info_body)

    stub_request(:get, %r{http.*://ipinfo\.io/.*\?token.*})
      .with(
        headers: {
          'Accept' => 'application/json',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => 'Bearer d3bb06e9a6567d',
          'User-Agent' => 'IPinfoClient/Ruby/2.4.0',
        },
      )
      .to_return(status: 200, body: ip_info_body, headers: {})
  end

  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!

  # Clean up uploaded images
  config.after(:all) do
    # Get rid of the linked images
    if Rails.env.test?
      FileUtils.rm_rf(Dir[Rails.root.join('public/uploads/test/[^.]*').to_s])
      FileUtils.rm_rf(Dir[Rails.root.join('public/uploads/tmp/test/[^.]*').to_s])
    end
  end

  config.after(:suite) do
    delete_test_indices
  end

  # Class to mock IPinfo
  class MockIpinfo
    delegate :longitude, to: :'Faker::Address'

    delegate :latitude, to: :'Faker::Address'
  end

  def ip_info_body
    {
      ip: Faker::Internet.ip_v4_address,
      hostname: Faker::Internet.domain_name,
      city: Faker::Address.city,
      region: Faker::Address.state,
      country: Faker::Address.country_code,
      loc: "#{Faker::Address.latitude},#{Faker::Address.longitude}",
      org: Faker::Company.name,
      postal: Faker::Address.zip,
      timezone: Faker::Address.time_zone,
    }.to_json
  end
end
