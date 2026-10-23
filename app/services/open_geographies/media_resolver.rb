# frozen_string_literal: true

module OpenGeographies
  # Resolves a thumbnail URL for a single OG media item, using a DB cache so
  # external API calls happen at most once per UUID per 30 days.
  class MediaResolver
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
      # For embedded media the provider's own thumbnail comes first: their
      # content_url is often the media itself (e.g. a 3D model), not a picture.
      thumbnail_url =
        if provider
          provider_thumbnail(provider, @og_medium[:embed_url]) || image_content_url
        else
          image_content_url
        end
      { provider:, thumbnail_url: }
    end

    # content_url, if it's an image.
    def image_content_url
      url = @og_medium[:content_url]
      return if url.blank?

      response = HTTParty.head(url, timeout: 10)
      url if response.success? && response.headers['content-type'].to_s.start_with?('image/')
    rescue StandardError
      nil
    end

    # The provider's own thumbnail, the same one a natively added medium gets.
    def provider_thumbnail(provider, embed_url)
      return if provider.nil? || embed_url.blank?

      provider_class = VideoProviders.class_for(provider)
      embed_id = provider_class.embed_id_from(embed_url)
      return if embed_id.nil?

      provider_class.new(VideoProviders::Item.new(embed_id)).thumbnail_url
    rescue StandardError => e
      Rails.logger.warn("OpenGeographies thumbnail fetch failed for #{embed_url}: #{e.message}")
      nil
    end

    def detect_provider(embed_url)
      return if embed_url.blank?

      VideoProviders.detect(embed_url)
    end
  end
end
