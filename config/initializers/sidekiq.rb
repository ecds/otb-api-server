# frozen_string_literal: true

redis_url = ENV.fetch('REDIS_URL') do
  "#{Rails.application.credentials.dig(Rails.env.to_sym, :redis_url)}/8"
end

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
  config.logger.level = Logger::ERROR
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
