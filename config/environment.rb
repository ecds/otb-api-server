# frozen_string_literal: true

# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.configure do
  config.force_ssl = true
  config.active_support.to_time_preserves_timezone = :zone
end
Rails.application.initialize!
