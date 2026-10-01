# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'action_cable/engine'
# require "sprockets/railtie"
require 'rails/test_unit/railtie'
require 'apartment/elevators/generic'
require 'active_storage/engine'
require 'ipinfo-rails'
require 'httparty'
require 'http'
require 'json'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module OpenTourApi
  # Base class for the app.
  class Application < Rails::Application
    class DirectoryElevator < Apartment::Elevators::Generic
      def call(env)
        request = Rack::Request.new(env)
        tenant_name = parse_tenant_name(request)

        return @app.call(env) unless tenant_name

        redirect = renamed_tenant_redirect(tenant_name, request)
        return redirect if redirect

        Apartment::Tenant.switch(tenant_name) { @app.call(env) }
      end

      def parse_tenant_name(request)
        # request is an instance of Rack::Request
        tenant_name = request.fullpath.split('/')[1]
        tenants_to_ignore = ['auth', 'rails', 'sidekiq', 'favicon.ico', 'health']

        return 'public' if tenants_to_ignore.include?(tenant_name)

        tenant_name
      end

      private

      # If `tenant_name` is a subdir a TourSet used to have (before a rename),
      # redirect to the same path under its current subdir instead of trying
      # (and failing) to switch to a Postgres schema that no longer exists
      # under that name.
      def renamed_tenant_redirect(tenant_name, request)
        return if TourSet.exists?(subdir: tenant_name)

        history = TourSetSubdirHistory.find_by(subdir: tenant_name)
        return unless history

        new_path = request.fullpath.sub("/#{tenant_name}", "/#{history.tour_set.subdir}")
        [308, { 'Location' => new_path }, []]
      end
    end
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults(7.0)

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    # config.active_storage.variant_processor = :vips
    config.middleware.use(ActionDispatch::Cookies)
    config.middleware.use(ActionDispatch::Session::CookieStore)
    config.action_dispatch.cookies_serializer = :json
    config.middleware.use(
      IPinfoMiddleware,
      { token: ENV['IPINFO_TOKEN'] || Rails.application.credentials.dig(:ipinfo) },
    )
    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
    config.middleware.use(DirectoryElevator)
    config.active_job.queue_adapter = :sidekiq
    config
  end
end
