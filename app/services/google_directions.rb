class GoogleDirections

  def initialize(origin, destinations, stops_count, mode)
    @query = {
      origins: origin.join(','),
      destinations: destinations.map { |d| d.join(',') }.join('|'),
      mode: mode,
      key: Rails.application.credentials.dig(:g_maps_key)
    }

    @stops_count = stops_count
  end

  def matrix
    response = HTTParty.get(
      "https://maps.googleapis.com/maps/api/distancematrix/json?#{@query.to_query}"
    ).with_indifferent_access

    return nil if response[:rows].first[:elements].first[:status] == 'ZERO_RESULTS'

    response
  end

  def durations
    matrix.nil? ? nil : matrix[:rows].first[:elements].map { |e| e[:duration][:value] if e[:duration].present? }.reject { |d| d.nil? }
  end

  def duration
    durations.nil? ? nil : durations.sum + 600 + (@stops_count * 600)
  end
end
