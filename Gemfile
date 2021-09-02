# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1.0'
gem 'rack', '>= 2.0.6'
gem 'pg'
gem 'mysql2'
# Multitenancy for Rails and ActiveRecord
gem 'ros-apartment', require: 'apartment'
# For JSONAPI responses
gem 'active_model_serializers', '~> 0.10.12'
# Use Puma as the app server
gem 'puma', '~> 4.3.0'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 3.0'
gem 'actionview', '>= 5.2.2.1'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# gem 'ecds_rails_auth_engine', path: '../ecds_auth_engine'
gem 'ecds_rails_auth_engine', git: 'https://github.com/ecds/ecds_rails_auth_engine.git', branch: 'feature/fauxoauth'
# gem 'ecds_rails_auth_engine', path: '/data/ecds_auth_engine'
gem 'cancancan', '~> 2.0'

# Active Storage will land in 5.2
gem 'carrierwave', '~> 1.0'
gem 'carrierwave-base64'
gem 'mini_magick'
gem 'image_processing', '~> 1.2'
gem 'ferrum'
gem 'aws-sdk-s3', '~> 1'

# RGeo is a geospatial data library for Ruby.
# https://github.com/rgeo/rgeo
gem 'rgeo'
gem 'google_maps_service'
gem 'ipinfo-rails'


# Vidoe provider APIs
gem 'vimeo'
gem 'yt'
gem 'youtube_rails'

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'

# TODO: should probably only require this for :test
gem 'faker', git: 'https://github.com/stympy/faker.git', branch: 'master'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  # gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # gem "test-prof"
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'rspec-rails', '~> 4.0.2'
  # Use Capistrano for deployment
  gem 'capistrano-rails'
  gem 'capistrano-rbenv', '~> 2.0'
  gem 'capistrano-passenger'
end


group :test do
  gem 'factory_bot'
  gem 'factory_bot_rails'
  gem 'shoulda-matchers', '~> 4.5.1' #git: 'https://github.com/thoughtbot/shoulda-matchers.git', branch: 'rails-5'
  gem 'database_cleaner'
  gem 'webmock'
  gem 'coveralls', require: false
  gem 'term-ansicolor'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
