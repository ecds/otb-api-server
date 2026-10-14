# frozen_string_literal: true

# Builds a short postal-style address ("315 Chester Avenue Southeast, Atlanta,
# GA 30316") from Nominatim's address parts. Falls back to the given text when
# there's no street (parks, landmarks, rural places).
module AddressFormatter
  CITY_KEYS = ['city', 'town', 'village', 'hamlet', 'municipality', 'suburb'].freeze

  class << self
    def format(parts, fallback = nil)
      parts = (parts || {}).to_h.stringify_keys
      street = parts.values_at('house_number', 'road').compact.join(' ')
      city = parts.values_at(*CITY_KEYS).compact.first
      state =
        if parts['country_code'] == 'us'
          # "US-GA" -> "GA"
          parts['ISO3166-2-lvl4'].to_s.split('-').last.presence || parts['state']
        else
          parts['state'] || parts['region']
        end
      state_zip = [state, parts['postcode']].compact.join(' ')

      formatted = [street, city, state_zip].compact_blank
      formatted.size >= 2 && street.present? ? formatted.join(', ') : fallback
    end
  end
end
