GoogleMapsService.configure do |config|
  if ENV['RAILS_ENV'] == 'test'
    config.key = 'FAkeFaK-E_fAkeChv-P3nchtQYHoCLfFzn9ylr8'
  else
    config.key = Rails.application.credentials.dig(:g_maps_key)
  end
end
