# frozen_string_literal: true

module OpenGeographies
  class DeserializerV1
    PROVIDER_PATTERNS = [
      { name: 'youtube',      pattern: /youtube\.com|youtu\.be/ },
      { name: 'vimeo',        pattern: /vimeo\.com/ },
      { name: 'soundcloud',   pattern: /soundcloud\.com/ },
      { name: 'sketchfab',    pattern: /sketchfab\.com|skfb\.ly/ },
      { name: 'matterport',   pattern: /matterport\.com/ },
      { name: 'morphosource', pattern: /morphosource\.org/ },
    ].freeze

    def initialize(og_data)
      @og_data = og_data
    end

    def call
      {
        bounds: bounds,
        stops: stops,
        stop_count: @og_data[:stops].count,
      }
    end

    private

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
        cached = MediaResolver.new(medium).call
        thumbnail = cached&.thumbnail_url || medium[:thumbnail] || medium[:preview]
        {
          title: medium[:name],
          provider: cached&.provider,
          embed: medium[:embed_url],
          files: {
            original: medium[:content_url],
            mobile: thumbnail,
            tablet: medium[:preview] || thumbnail,
            desktop: medium[:content_url],
          },
        }
      end
    end
  end
end
