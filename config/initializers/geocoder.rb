# frozen_string_literal: true

Geocoder.configure(
  lookup: :ipinfo_io,
  ipinfo_io: {
    api_key: Rails.application.credentials.dig(:ipinfo),
  },
  # Used for addresses (see AddressGeocoder) by passing lookup: :nominatim.
  # Nominatim's usage policy asks for an identifying User-Agent.
  nominatim: {
    http_headers: { 'User-Agent' => 'OpenTourBuilder/4.0 (info@opentour.site)' },
  },
  timeout: 5,
)
