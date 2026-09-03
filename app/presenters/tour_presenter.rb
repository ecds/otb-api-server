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

    @og_data = JSON.parse(response.body, symbolize_names: true)
    to_otb
  rescue HTTP::TimeoutError, HTTP::Error => e
    Rails.logger.error("Geography #{@record["open_geographies_endpoint"]} API failed: #{e.message}")
    nil
  end

  def to_otb
    @data = {
      **@data.as_json,
      bounds: to_bounds,
      stops: to_stops,
      stop_count: @og_data[:stops].count,
    }
  end

  def to_bounds
    factory = RGeo::Cartesian.factory
    bbox = RGeo::Cartesian::BoundingBox.new(factory)
    points = @og_data[:stops].map do |og_stop|
      factory.point(
        og_stop[:geo][:point][:lon],
        og_stop[:geo][:point][:lat],
      )
    end

    points.each { |pt| bbox.add(pt) }
    {
      south: bbox.min_y,
      north: bbox.max_y,
      west: bbox.max_x,
      east: bbox.min_x,
      centerLat: bbox.center_y,
      centerLng: bbox.center_x,
    }
  end

  def to_stops
    @og_data[:stops].each_with_index.map do |og_stop, index|
      position = index + 1
      next_stop = neighbor(@og_data[:stops][position]) unless position == @og_data[:stops].count
      previous_stop = neighbor(@og_data[:stops][index - 1]) if index.nonzero?

      {
        position:,
        next: next_stop,
        previous: previous_stop,
        address: og_stop[:address],
        description: og_stop[:description],
        meta_description: og_stop[:short_description],
        lat: og_stop[:geo][:point][:lat],
        lng: og_stop[:geo][:point][:lon],
        media: to_media(og_stop[:media]),
      }
    end
  end

  def neighbor(og_stop)
    {
      id: og_stop[:id],
      slug: og_stop[:slug],
      title: og_stop[:title],
    }
  end

  def to_media(og_media)
    og_media.map do |medium|
      # TODO: It would be nice to leverage IIIF here to get image variants
      # consistent with how we construct them, but requesting the manifest
      # for each is too much overhead. Conversely, it would also be nice for
      # OTB to use IIIF and got out of the business of creating variants.
      {
        title: medium[:name],
        files: {
          original: medium[:content_url],
          mobile: medium[:preview],
          tablet: medium[:preview],
          desktop: medium[:content_url],
          embed: medium[:embed_url],
        },
      }
    end
  end
end
