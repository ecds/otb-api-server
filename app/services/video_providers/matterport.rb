# frozen_string_literal: true

module VideoProviders
  class Matterport < Base
    EMBED_ID = %r{matterport\.com/show/?\?(?:[^#]*&)?m=([A-Za-z0-9]+)}

    def embed_url
      "//my.matterport.com/show/?m=#{@medium.embed_id}"
    end

    # Built from the id rather than read from the model's page: Matterport
    # serves the page without its og:image to requests from AWS.
    def thumbnail_url
      "https://my.matterport.com/api/v2/player/models/#{@medium.embed_id}/thumb/"
    end

    def call
      image_body = super
      @medium.filename = "#{@medium.embed_id}.jpg"
      image_body
    end
  end
end
