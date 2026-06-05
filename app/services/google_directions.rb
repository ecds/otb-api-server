# frozen_string_literal: true

class GoogleDirections
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

  def matrix
    response = HTTParty.get(
      "https://maps.googleapis.com/maps/api/distancematrix/json?#{@query.to_query}",
    ).with_indifferent_access

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
      end.reject { |d| d.nil? }
    end
  end

  def duration
    durations.nil? ? nil : durations.sum + 600 + (@stops_count * 600)
  end
end
