# frozen_string_literal: true

# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.configure do
  config.force_ssl = true
end
Rails.application.initialize!
