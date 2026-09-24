# frozen_string_literal: true

module VideoProviders
  class Youtube < Base
    def embed_url
      "//www.youtube.com/embed/#{@medium.embed_id}"
    end

    def call
      metadata = Yt::Video.new(id: @medium.embed_id)
      @medium.title = metadata.title
      @medium.caption = metadata.description
      @medium.embed = embed_url
      HTTParty.get("https://img.youtube.com/vi/#{@medium.embed_id}/0.jpg").body
    rescue Yt::Errors::NoItems
      @medium.provider = nil
      @medium.embed_id = nil
      nil
    end
  end
end
