# frozen_string_literal: true

class TourPresenter
  # The parts of an Open Geographies preview the public tour uses. The rest
  # (problems, context, sanitized HTML, ...) is for the admin.
  OPEN_GEOGRAPHIES_FIELDS = [:bounds, :stops, :stop_count].freeze

  def initialize(record, tour_set)
    @record = record
    @tour_set = tour_set
  end

  def as_json(*)
    @data = @record.to_h

    merge_open_geographies_stops if @record['open_geographies_endpoint'].present?

    { tour: @data.as_json, tour_set: @tour_set.as_json }
  end

  private

  # Fetched (and cached briefly) by OpenGeographies::Source, which the admin
  # preview shares. If the source can't be read, the tour is served without
  # its Open Geographies stops rather than failing.
  def merge_open_geographies_stops
    preview = OpenGeographies::Source.new(@record['open_geographies_endpoint']).call
    og_data = preview.slice(*OPEN_GEOGRAPHIES_FIELDS)
    og_data[:stops] = og_data[:stops].map { |stop| stop.except(:description_html) }
    @data = @data.as_json.merge(og_data.deep_stringify_keys)
  rescue OpenGeographies::Source::Error => e
    Rails.logger.error("Open Geographies #{@record["open_geographies_endpoint"]} failed: #{e.message}")
  end
end
