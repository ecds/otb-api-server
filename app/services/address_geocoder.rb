# frozen_string_literal: true

# Address search and reverse lookup through Nominatim, for the admin.
# Results are cached, and requests are limited to one per second per process,
# as Nominatim's usage policy requires.
module AddressGeocoder
  Result = Struct.new(:lat, :lng, :address, :name, keyword_init: true)

  CACHE_FOR = 30.days
  MIN_INTERVAL = 1.0

  @lock = Mutex.new
  @last_request_at = 0.0

  class << self
    def search(query)
      query = query.to_s.squish
      return if query.blank?

      cached("search/#{query.downcase}") { lookup(query) }
    end

    def reverse(lat, lng)
      lat = Float(lat, exception: false)
      lng = Float(lng, exception: false)
      return unless lat&.between?(-90, 90) && lng&.between?(-180, 180)

      # About a metre; nearby drags share a result.
      cached("reverse/#{lat.round(5)},#{lng.round(5)}") { lookup([lat, lng]) }
    end

    private

    # Misses aren't cached, so a later attempt can still find a place.
    def cached(key, &)
      Rails.cache.fetch("address_geocoder/#{key}", expires_in: CACHE_FOR, skip_nil: true, &)
    end

    def lookup(query)
      result = throttled { Geocoder.search(query, lookup: :nominatim) }.first
      return if result.nil?

      data = result.data
      Result.new(
        lat: result.latitude.to_f,
        lng: result.longitude.to_f,
        address: AddressFormatter.format(data['address'], data['display_name']),
        name: data['name'].presence,
      ).to_h
    end

    def throttled
      @lock.synchronize do
        wait = MIN_INTERVAL - (Process.clock_gettime(Process::CLOCK_MONOTONIC) - @last_request_at)
        sleep(wait) if wait.positive?
        yield
      ensure
        @last_request_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
