Geocoder.configure(
  lookup: :ipinfo_io,
  ipinfo_io: {
    api_key: Rails.application.credentials.dig(:ipinfo)
  }
)
