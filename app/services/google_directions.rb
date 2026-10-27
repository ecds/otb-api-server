# frozen_string_literal: true

class GoogleDirections
  # One leg's travel time in seconds, or why there isn't one: :no_route (Google
  # found no way there), :refused (Google turned the request down; `status`
  # says why), or :unreachable (no usable answer from Google).
  Leg = Struct.new(:seconds, :problem, :status, keyword_init: true)

  TIMEOUT = 10

  def initialize(origin, destinations, stops_count, mode)
    google_key = ENV['RAILS_ENV'] == 'test' ? 'FAkeFaK-E_fAkeChv-P3nchtQYHoCLfFzn9ylr8' : Rails.application.credentials.dig(:g_maps_key)
    @query = {
      origins: origin.join(','),
      destinations: destinations.map { |d| d.join(',') }.join('|'),
      mode: mode,
      key: google_key,
    }

    @stops_count = stops_count
  end

  # From the origin to the destinations, added up, as `durations` does.
  def leg
    response = fetch
    return Leg.new(problem: :unreachable) if response.nil?
    return Leg.new(problem: :refused, status: response[:status]) unless response[:status] == 'OK'

    elements = Array(response.dig(:rows, 0, :elements))
    timed = elements.select { |element| element[:status] == 'OK' && element.dig(:duration, :value) }
    return Leg.new(seconds: timed.sum { |element| element.dig(:duration, :value) }) if timed.any?

    Leg.new(problem: :no_route, status: elements.first&.dig(:status))
  end

  def matrix
    response = fetch
    return if response.nil?
    return if response[:status] && response[:rows].nil?

    return if response[:rows].first[:elements].first[:status] == 'ZERO_RESULTS'

    response
  end

  def durations
    if matrix.nil?
      nil
    else
      matrix[:rows].first[:elements].map do |e|
        e[:duration][:value] if e[:duration].present?
      end.reject(&:nil?)
    end
  end

  def duration
    durations.nil? ? nil : durations.sum + 600 + (@stops_count * 600)
  end

  private

  # One request per instance; nil when Google can't be reached or doesn't
  # answer with JSON.
  def fetch
    return @response if defined?(@response)

    response = HTTParty.get(
      "https://maps.googleapis.com/maps/api/distancematrix/json?#{@query.to_query}",
      timeout: TIMEOUT,
    )
    parsed = response.parsed_response
    @response = parsed.is_a?(Hash) ? parsed.with_indifferent_access : nil
  rescue HTTParty::Error, SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError => e
    Rails.logger.error("Google Directions failed: #{e.class}: #{e.message}")
    @response = nil
  end
end
