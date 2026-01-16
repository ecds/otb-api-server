# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = { url: "#{Rails.application.credentials.dig(ENV['RAILS_ENV'].to_sym, :redis_url)}/8" }
  config.logger.level = Logger::ERROR
end

Sidekiq.configure_client do |config|
  config.redis = { url: "#{Rails.application.credentials.dig(ENV['RAILS_ENV'].to_sym, :redis_url)}/8" }
end
