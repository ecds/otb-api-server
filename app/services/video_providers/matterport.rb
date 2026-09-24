# frozen_string_literal: true

module VideoProviders
  class Matterport < Base
    def embed_url
      "//my.matterport.com/show/?m=#{@medium.embed_id}"
    end

    def call
      image_body = super
      @medium.filename = "#{@medium.embed_id}.jpg"
      image_body
    end
  end
end
