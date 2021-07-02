# frozen_string_literal: true

# require 'directory_elevator'
Apartment.configure do |config|
  config.tenant_names = -> { TourSet.pluck :subdir }
  config.excluded_models = ['User', 'Role', 'TourSetAdmin', 'TourSet', 'EcdsRailsAuthEngine::Login', 'Theme']
  config.persistent_schemas = ['shared_extensions']
end
