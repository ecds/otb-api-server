# frozen_string_literal: true

module OpenGeographies
  # Fetches and checks an Open Geographies tour document, and turns its stops
  # into OpenTour's stop shape.
  #
  # Every OG stop declares its schema with an @context such as
  # https://opengeographies.org/api/v1/context.json; the version in that URL
  # picks the deserializer. Stops without one are left out and reported.
  class Source
    class Error < StandardError; end

    CONTEXT = %r{\Ahttps://opengeographies\.org/api/(v\d+)/context\.json\z}
    DESERIALIZERS = { 'v1' => DeserializerV1 }.freeze
    TIMEOUT = 10
    CACHE_FOR = 5.minutes

    attr_reader :url

    def initialize(url)
      @url = url.to_s.strip
    end

    # Returns { context:, version:, stops:, bounds:, stop_count:, problems:,
    # fetched_at: }. Cached briefly so repeated previews don't refetch;
    # refresh: true fetches again. Raises Error when the document can't be
    # used at all.
    def call(refresh: false)
      raise(Error, 'No Open Geographies URL is set for this tour.') if url.blank?

      key = "open_geographies/#{Digest::SHA256.hexdigest(url)}"
      Rails.cache.delete(key) if refresh
      Rails.cache.fetch(key, expires_in: CACHE_FOR) { build }
    end

    private

    def build
      document = fetch
      og_stops = Array(document[:stops])
      versions = og_stops.filter_map { |stop| version_of(stop) }.uniq
      if versions.empty?
        raise(Error, "This doesn't look like an Open Geographies tour: its stops have no Open Geographies @context.")
      end
      raise(Error, "The stops use different Open Geographies versions (#{versions.join(", ")}).") if versions.size > 1

      version = versions.first
      raise(Error, "Open Geographies #{version} isn't supported yet.") unless DESERIALIZERS.key?(version)

      context = og_stops.lazy.map { |stop| stop[:'@context'] }.find { |c| c.to_s.match?(CONTEXT) }
      problems = problems_for(og_stops)
      placeable = og_stops.select { |stop| version_of(stop) && point(stop) }
      result = placeable.any? ? DESERIALIZERS[version].new(document.merge(stops: placeable)).call : { stops: [], bounds: nil, stop_count: 0 }

      result.merge(context:, version:, problems:, fetched_at: Time.current.iso8601)
    end

    def fetch
      uri = URI.parse(url)
      raise(Error, 'The Open Geographies URL must start with http:// or https://.') unless uri.is_a?(URI::HTTP)

      response = HTTParty.get(url, timeout: TIMEOUT, headers: { 'Accept' => 'application/json' })
      raise(Error, "Open Geographies responded with #{response.code}.") unless response.success?

      document = JSON.parse(response.body, symbolize_names: true)
      raise(Error, 'The Open Geographies response is not a tour document.') unless document.is_a?(Hash)

      document
    rescue URI::InvalidURIError
      raise(Error, "That isn't a valid URL.")
    rescue JSON::ParserError
      raise(Error, 'The Open Geographies response is not valid JSON.')
    rescue Timeout::Error # includes Net::OpenTimeout and Net::ReadTimeout
      raise(Error, 'Open Geographies took too long to respond.')
    rescue SocketError, SystemCallError, OpenSSL::SSL::SSLError, HTTParty::Error => e
      raise(Error, "Couldn't reach Open Geographies (#{e.class.name.demodulize}).")
    end

    def version_of(stop)
      stop[:'@context'].to_s.match(CONTEXT)&.captures&.first
    end

    def point(stop)
      lat = stop.dig(:geo, :point, :lat)
      lon = stop.dig(:geo, :point, :lon)
      [lat, lon] if lat.is_a?(Numeric) && lon.is_a?(Numeric)
    end

    # Things a curator should check. Stops without a location can't go on
    # the map, so they're left out of the preview and listed here.
    def problems_for(og_stops)
      problems = []
      problems << 'The tour has no stops.' if og_stops.empty?

      og_stops.each_with_index do |stop, index|
        label = stop[:name].presence || "Stop #{index + 1}"
        problems << "#{label} has no Open Geographies @context, so it can't be shown." unless version_of(stop)
        problems << "#{label} has no location, so it can't be shown." unless point(stop)
        problems << "Stop #{index + 1} has no name." if stop[:name].blank?
        problems << "#{label} has no images or media." if Array(stop[:media]).empty?
        repeated = Array(stop[:media]).group_by { |medium| medium[:uuid] }.count { |uuid, media| uuid && media.size > 1 }
        problems << "#{label} lists #{repeated == 1 ? "a medium" : "#{repeated} media"} more than once." if repeated.positive?
      end

      og_stops.group_by { |stop| stop[:uuid] }.each do |uuid, stops|
        problems << "#{stops.size} stops share the id #{uuid}." if uuid.present? && stops.size > 1
      end

      problems
    end
  end
end
