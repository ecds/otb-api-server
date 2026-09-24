# frozen_string_literal: true

module VideoProviders
  class Vimeo < Base
    def embed_url
      "//player.vimeo.com/video/#{@medium.embed_id}"
    end

    def call
      metadata = HTTParty.get("https://vimeo.com/api/oembed.json?url=https%3A//vimeo.com/video/#{@medium.embed_id}")
      @medium.title = metadata['title']
      @medium.caption = metadata['description']
      @medium.embed = embed_url
      thumbnail_width = metadata['thumbnail_width']
      thumbnail_height = metadata['thumbnail_height']
      scale_by = 1000 / thumbnail_width
      thumbnail_url = "#{metadata["thumbnail_url"].split("_")[0]}_#{thumbnail_width * scale_by}x#{thumbnail_height * scale_by}"
      HTTParty.get(thumbnail_url).body
    end
  end
end
