# frozen_string_literal: true

class TourPresenter
  DESERIALIZERS = {
    'v1' => OpenGeographies::DeserializerV1,
  }.freeze

  def initialize(record, tour_set)
    @record = record
    @tour_set = tour_set
  end

  def as_json(*)
    @data = @record.to_h

    fetch_geography_stops if @record['open_geographies_endpoint'].present?

    { tour: @data.as_json, tour_set: @tour_set.as_json }
  end

  private

  def fetch_geography_stops
    response = HTTParty.get(@record['open_geographies_endpoint'])
    return unless response.success?

    og_data = JSON.parse(response.body, symbolize_names: true)
    version = detect_version(og_data)
    deserializer_class = DESERIALIZERS.fetch(version, OpenGeographies::DeserializerV1)
    @data = @data.as_json.merge(deserializer_class.new(og_data).call.stringify_keys)
  rescue HTTP::TimeoutError, HTTP::Error => e
    Rails.logger.error("Geography #{@record["open_geographies_endpoint"]} API failed: #{e.message}")
    nil
  end

  def detect_version(og_data)
    context = og_data.dig(:stops, 0, :'@context').to_s
    context.match(%r{/api/(v\d+)/})&.captures&.first || 'v1'
  end
end
