GoogleMapsService.configure do |config|
  config.key = Rails.application.credentials.dig(:g_maps_key)
end
