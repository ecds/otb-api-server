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

    # Hosts the server may fetch Open Geographies documents from, set per
    # deployment in OPEN_GEOGRAPHIES_HOSTS (comma separated). "og.example.org"
    # matches that host; "*.example.org" matches its subdomains. Nothing is
    # allowed when it's unset.
    class << self
      def allowed_hosts
        ENV.fetch('OPEN_GEOGRAPHIES_HOSTS', '').split(',').map { |host| host.strip.downcase }.compact_blank
      end

      def allowed_host?(host)
        host = host.to_s.downcase
        host.present? && allowed_hosts.any? do |pattern|
          pattern.start_with?('*.') ? host.end_with?(pattern.delete_prefix('*')) : host == pattern
        end
      end

      # Why this URL can't be used, or nil when it can. Checked before
      # anything is fetched, and when a tour is saved.
      def url_problem(url)
        uri = URI.parse(url.to_s.strip)
        return 'The Open Geographies URL must start with http:// or https://.' unless uri.is_a?(URI::HTTP) && uri.host

        "#{uri.host} isn't an allowed Open Geographies host." unless allowed_host?(uri.host)
      rescue URI::InvalidURIError
        "That isn't a valid URL."
      end
    end

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

      result[:stops] = result[:stops].map { |stop| stop.merge(description_html: safe_html(stop[:description])) }
      result.merge(context:, version:, problems:, fetched_at: Time.current.iso8601)
    end

    def fetch
      problem = self.class.url_problem(url)
      raise(Error, problem) if problem

      # Redirects aren't followed: they could lead to a host that isn't allowed.
      response = HTTParty.get(url, timeout: TIMEOUT, follow_redirects: false, headers: { 'Accept' => 'application/json' })
      raise(Error, 'Open Geographies redirected to another address. Use the final URL instead.') if response.code.between?(300, 399)
      raise(Error, "Open Geographies responded with #{response.code}.") unless response.success?

      document = JSON.parse(response.body, symbolize_names: true)
      raise(Error, 'The Open Geographies response is not a tour document.') unless document.is_a?(Hash)

      document
    rescue JSON::ParserError
      raise(Error, 'The Open Geographies response is not valid JSON.')
    rescue Timeout::Error # includes Net::OpenTimeout and Net::ReadTimeout
      raise(Error, 'Open Geographies took too long to respond.')
    rescue SocketError, SystemCallError, OpenSSL::SSL::SSLError, HTTParty::Error => e
      raise(Error, "Couldn't reach Open Geographies (#{e.class.name.demodulize}).")
    end

    # The description is HTML from another site. This keeps formatting and
    # links but drops scripts, event handlers and styles, so the admin can
    # show it as HTML.
    def safe_html(html)
      Rails::Html::SafeListSanitizer.new.sanitize(html.to_s)
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

      missing_alt = og_stops.sum { |stop| Array(stop[:media]).count { |medium| medium[:alt_text].blank? } }
      if missing_alt.positive?
        problems << "#{missing_alt} #{missing_alt == 1 ? "image has" : "images have"} no alt text, " \
          "so #{missing_alt == 1 ? "it's" : "they're"} shown as decorative. Add alt text in Open Geographies."
      end

      og_stops.group_by { |stop| stop[:uuid] }.each do |uuid, stops|
        problems << "#{stops.size} stops share the id #{uuid}." if uuid.present? && stops.size > 1
      end

      problems
    end
  end
end
