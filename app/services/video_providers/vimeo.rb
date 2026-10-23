# frozen_string_literal: true

module VideoProviders
  class Vimeo < Base
    EMBED_ID = %r{vimeo\.com/(?:video/)?(\d+)}

    def embed_url
      "//player.vimeo.com/video/#{@medium.embed_id}"
    end

    # Vimeo's thumbnail, scaled up to about 1000px wide.
    def thumbnail_url
      width = metadata['thumbnail_width']
      height = metadata['thumbnail_height']
      return metadata['thumbnail_url'] unless width.to_i.positive? && height.to_i.positive?

      scale_by = 1000 / width
      "#{metadata["thumbnail_url"].split("_")[0]}_#{width * scale_by}x#{height * scale_by}"
    end

    def call
      @medium.title = metadata['title']
      @medium.caption = metadata['description']
      @medium.embed = embed_url
      HTTParty.get(thumbnail_url).body
    end

    private

    def metadata
      @metadata ||= HTTParty.get("https://vimeo.com/api/oembed.json?url=https%3A//vimeo.com/video/#{@medium.embed_id}")
    end
  end
end
