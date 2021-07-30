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
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  config.include RequestSpecHelper, type: :request
  config.include(RequestSpecHelper, type: :controller)
  config.include(SignedCookieHelper, type: :request)
  config.include(SignedCookieHelper, type: :controller)
  config.include FactoryBot::Syntax::Methods
  # start by truncating all the tables but then use the faster transaction strategy the rest of the time.
  config.before(:suite) do
    # DatabaseCleaner.clean_with(:truncation, except: [:modes, :roles])
    # DatabaseCleaner.strategy = :transaction
    # Truncating doesn't drop schemas, ensure we're clean here, app *may not* exist
    # begin
    #   Apartment::Tenant.drop('atlanta')
    # rescue
    #   nil
    # end
    # # Create the default tenant for our tests
    # TourSet.create(name: 'Atlanta')
    load Rails.root + 'db/seeds.rb'
  end

  # config.use_transactional_fixtures = true

  # start the transaction strategy as examples are run
  config.around(:each) do |example|
    # DatabaseCleaner.cleaning do
      example.run
    # end
  end

  config.before(:each) do
    # Start transaction for this test
    # DatabaseCleaner.start
    # Switch into the default tenant
    Apartment::Tenant.switch! TourSet.find(TourSet.pluck(:id).sample).subdir
    # host! 'atlanta.lvh.me'
    # load Rails.root + 'db/seeds.rb'
    stub_request(:any, 'https://placehold.it/300x300.png')
      .to_return(body: File.open(Rails.root + 'spec/factories/images/300x300.png'), status: 200)

    stub_request(:get, 'https://vimeo.com/api/oembed.json?url=https://vimeo.com/310645255')
      .to_return(
        body: "{ title: 'CycloramaBattleSites.org Stop 2', thumbnail_url: 'https://placehold.it/300x300.png' }",
        status: 200
      )

    stub_request(:get, 'https://vimeo.com/api/oembed.json?url=https://vimeo.com/video/310645255')
      .with(
        headers: {
          'Accept': '*/*',
          'Accept-Encoding': 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent': 'Ruby'
        }
      )
      .to_return(
        status: 200,
        body: '{ "title": "CycloramaBattleSites.org Stop 2", "thumbnail_url": "https://placehold.it/300x300.png" }',
        headers: { 'content-type': 'application/json' }
      )

    stub_request(:get, 'https://vimeo.com/310645255')
      .to_return(
        status: 200
      )

    stub_request(:get, 'https://youtu.be/F9ULbmCvmxY')
      .to_return(
        status: 200
      )

    stub_request(:get, 'https://img.youtube.com/vi/F9ULbmCvmxY/0.jpg')
      .to_return(
        body: File.open(Rails.root + 'spec/factories/images/0.jpg'),
        status: 200
      )

    stub_request(
      :get,
      'https://www.googleapis.com/youtube/v3/videos?id=F9ULbmCvmxY&key=AIzaSyAafrj3VvNLJNXeW5-NNCVwY5cdB06p1_s&part=snippet'
    )
    .to_return(
      status: 200,
      body: '{"items": [{ "id": "F9ULbmCvmxY",  "snippet": { "title": "Goodie Mob - Black Ice (Sky High) ft. OutKast", "description": "Music video by Goodie Mob feat. OutKast performing Black Ice (Sky High). (C) 1998 LaFace Records LLC" }}] }',
      headers: { 'content-type': 'application/json' }
    )

    stub_request(:get, 'https://www.youtube.com/watch?v=F9ULbmCvmxY')
      .to_return(status: 200, body: '', headers: {})

    stub_request(:get, 'https://vimeo.com/F9ULbmCvmxY')
      .to_return(status: 404, body: '', headers: {})

    stub_request(:get, 'https://vimeo.com/https://youtu.be/F9ULbmCvmxY')
      .to_return(status: 404, body: '', headers: {})

    stub_request(:get, 'https://vimeo.com/https://www.youtube.com/watch?v=F9ULbmCvmxY')
      .to_return(status: 404, body: '', headers: {})

  end

  config.after(:each) do
    # Reset tentant back to `public`
    # Apartment::Tenant.reset
    # Rollback transaction
    # DatabaseCleaner.clean
  end

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  # Clean up uploaded images
  config.after(:all) do
    # Get rid of the linked images
    if Rails.env.test?
      FileUtils.rm_rf(Dir["#{Rails.root}/public/uploads/test/[^.]*"])
      FileUtils.rm_rf(Dir["#{Rails.root}/public/uploads/tmp/test/[^.]*"])
    end
  end

  config.after(:suite) do
    # TourSet.all.each { |ts| ts.destroy }
  end
end
