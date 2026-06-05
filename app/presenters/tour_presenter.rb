# frozen_string_literal: true

# app/presenters/tour_presenter.rb
class TourPresenter
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
    response = HTTParty.get(
      @record['open_geographies_endpoint'],
    )
    return unless response.success?

    og_data = JSON.parse(response.body)
    @data[:stops] = og_data['stops']
    @data[:stop_count] = og_data['stops'].count
    @data[:bounds] = og_data['bounds']
  rescue HTTP::TimeoutError, HTTP::Error => e
    Rails.logger.error("Geography #{@record["open_geographies_endpoint"]} API failed: #{e.message}")
    nil
  end
end
