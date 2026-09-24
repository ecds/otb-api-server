# frozen_string_literal: true

module OpenGeographies
  # Resolves a thumbnail URL for a single OG media item, using a DB cache so
  # external API calls happen at most once per UUID per 30 days.
  class MediaResolver
    # How to extract a provider-specific thumbnail URL from an embed URL.
    # Each entry returns a URL string, or nil to fall through to the next step.
    THUMBNAIL_FETCHERS = {
      'youtube' => lambda { |embed_url|
        id = embed_url.match(%r{(?:youtube\.com/(?:watch\?v=|embed/)|youtu\.be/)([A-Za-z0-9_-]+)}i)&.captures&.first
        "https://img.youtube.com/vi/#{id}/0.jpg" if id
      },
      'vimeo' => lambda { |embed_url|
        id = embed_url.match(%r{vimeo\.com/(?:video/)?(\d+)})&.captures&.first
        if id
          data = HTTParty.get("https://vimeo.com/api/oembed.json?url=https%3A//vimeo.com/video/#{id}")
          data['thumbnail_url'] if data.success?
        end
      },
      'soundcloud' => lambda { |embed_url|
        id = embed_url.match(%r{api\.soundcloud\.com/tracks/(\d+)})&.captures&.first ||
          embed_url.match(%r{soundcloud\.com/tracks/(\d+)})&.captures&.first
        if id
          data = HTTParty.get(
            "https://soundcloud.com/oembed?url=https://api.soundcloud.com/tracks/#{id}&format=json",
            format: :plain,
          )
          JSON.parse(data.body)['thumbnail_url'] if data.success?
        end
      },
      'sketchfab' => lambda { |embed_url|
        id = embed_url.match(%r{sketchfab\.com/models/([0-9a-f]{32})}i)&.captures&.first
        if id
          doc = Nokogiri::HTML(HTTParty.get("https://sketchfab.com/models/#{id}/embed").body)
          doc.at_xpath('/html/head/meta[@property="og:image"]')&.[](:content)
        end
      },
      'matterport' => lambda { |embed_url|
        id = URI.parse(embed_url).query&.then { |q| URI.decode_www_form(q).to_h['m'] }
        if id
          doc = Nokogiri::HTML(HTTParty.get("https://my.matterport.com/show/?m=#{id}").body)
          doc.at_xpath('/html/head/meta[@property="og:image"]')&.[](:content)
        end
      },
    }.freeze

    def initialize(og_medium)
      @og_medium = og_medium
    end

    def call
      uuid = @og_medium[:uuid]
      cached = OpenGeographiesMedium.find_by(uuid:)
      return cached if cached && !cached.stale?

      resolved = resolve
      attrs = {
        uuid:,
        provider: resolved[:provider],
        embed_url: @og_medium[:embed_url],
        thumbnail_url: resolved[:thumbnail_url],
      }

      if cached
        cached.update(attrs)
        cached
      else
        OpenGeographiesMedium.create(attrs)
      end
    end

    private

    def resolve
      provider = detect_provider(@og_medium[:embed_url])
      thumbnail_url = working_content_url || provider_thumbnail(provider, @og_medium[:embed_url])
      { provider:, thumbnail_url: }
    end

    def working_content_url
      url = @og_medium[:content_url]
      return if url.blank?

      response = HTTParty.head(url)
      url if response.success?
    rescue StandardError
      nil
    end

    def provider_thumbnail(provider, embed_url)
      return if provider.nil? || embed_url.blank?

      fetcher = THUMBNAIL_FETCHERS[provider]
      fetcher&.call(embed_url)
    rescue StandardError => e
      Rails.logger.warn("OpenGeographies thumbnail fetch failed for #{embed_url}: #{e.message}")
      nil
    end

    def detect_provider(embed_url)
      return if embed_url.blank?

      DeserializerV1::PROVIDER_PATTERNS.find { |p| p[:pattern].match?(embed_url) }&.dig(:name)
    end
  end
end
