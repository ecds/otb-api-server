# frozen_string_literal: true

module VideoProviders
  class Youtube < Base
    EMBED_ID = %r{(?:youtube\.com/(?:watch\?(?:[^#]*&)?v=|embed/|shorts/)|youtu\.be/)([A-Za-z0-9_-]{6,})}

    def embed_url
      "//www.youtube.com/embed/#{@medium.embed_id}"
    end

    def thumbnail_url
      "https://img.youtube.com/vi/#{@medium.embed_id}/0.jpg"
    end

    def call
      metadata = Yt::Video.new(id: @medium.embed_id)
      @medium.title = metadata.title
      @medium.caption = metadata.description
      @medium.embed = embed_url
      HTTParty.get(thumbnail_url).body
    rescue Yt::Errors::NoItems
      @medium.provider = nil
      @medium.embed_id = nil
      nil
    end
  end
end
