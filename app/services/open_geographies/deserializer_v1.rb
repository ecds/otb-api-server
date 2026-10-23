# frozen_string_literal: true

module OpenGeographies
  class DeserializerV1
    def initialize(og_data)
      @og_data = og_data.merge(stops: sorted_stops(og_data[:stops]))
    end

    def call
      {
        bounds: bounds,
        stops: stops,
        stop_count: @og_data[:stops].count,
      }
    end

    private

    # Stops in their Open Geographies order. Stops without an order keep their
    # listed position, after those that have one.
    def sorted_stops(og_stops)
      ordered, unordered = Array(og_stops).partition { |stop| stop[:order].is_a?(Numeric) }
      # sort_by isn't stable, so ties fall back to the listed position.
      ordered.each_with_index.sort_by { |stop, index| [stop[:order], index] }.map(&:first) + unordered
    end

    def bounds
      factory = RGeo::Cartesian.factory
      bbox = RGeo::Cartesian::BoundingBox.new(factory)
      @og_data[:stops].each do |og_stop|
        bbox.add(factory.point(og_stop[:geo][:point][:lon], og_stop[:geo][:point][:lat]))
      end
      {
        south: bbox.min_y,
        north: bbox.max_y,
        west: bbox.min_x,
        east: bbox.max_x,
        centerLat: bbox.center_y,
        centerLng: bbox.center_x,
      }
    end

    def stops
      @og_data[:stops].each_with_index.map do |og_stop, index|
        position = index + 1
        count = @og_data[:stops].count
        next_stop = neighbor(@og_data[:stops][position]) unless position == count
        previous_stop = neighbor(@og_data[:stops][index - 1]) if index.nonzero?

        {
          address: og_stop[:address],
          description: og_stop[:description],
          id: og_stop[:uuid],
          lat: og_stop[:geo][:point][:lat],
          lng: og_stop[:geo][:point][:lon],
          media: media(og_stop[:media] || []),
          meta_description: og_stop[:short_description],
          next: next_stop,
          position:,
          previous: previous_stop,
          sanitized_description: HtmlSanitizer.accessible(og_stop[:description]),
          slug: og_stop[:slug],
          slugs: og_stop[:slugs],
          title: og_stop[:name],
        }
      end
    end

    def neighbor(og_stop)
      {
        id: og_stop[:uuid],
        slug: og_stop[:slug],
        title: og_stop[:name],
      }
    end

    def media(og_media)
      og_media.map do |medium|
        # Only media that embed something, or come without a picture, need
        # their thumbnail looked up; images use the one OG provides.
        needs_lookup = medium[:embed_url].present? || (medium[:thumbnail].blank? && medium[:preview].blank?)
        cached = MediaResolver.new(medium).call if needs_lookup
        thumbnail = cached&.thumbnail_url || medium[:thumbnail] || medium[:preview]
        # Same embed fields a natively added medium has.
        embed = Embed.call(medium[:embed_url])
        alt_text = medium[:alt_text].presence
        {
          title: medium[:name],
          alt_text:,
          # Created outside OpenTour, so an image without alt text is published
          # as decorative (empty alt) but still flagged for the curator.
          decorative: alt_text.nil?,
          missing_alt_text: alt_text.nil?,
          provider: embed&.dig(:provider) || cached&.provider,
          embed: embed&.dig(:embed),
          embed_id: embed&.dig(:embed_id),
          video: embed&.dig(:embed_id),
          files: embed ? embed_files(thumbnail) : image_files(medium, thumbnail),
        }
      end
    end

    def image_files(medium, thumbnail)
      {
        original: medium[:content_url],
        mobile: thumbnail,
        tablet: medium[:preview] || thumbnail,
        desktop: medium[:content_url],
      }
    end

    # Like a natively added embed, every size is the thumbnail picture; the
    # content itself (e.g. a 3D model) is only shown through the embed.
    def embed_files(thumbnail)
      { original: thumbnail, mobile: thumbnail, tablet: thumbnail, desktop: thumbnail }
    end
  end
end
