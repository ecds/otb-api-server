# frozen_string_literal: true

module VideoProviders
  class Soundcloud < Base
    def embed_url
      "//w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/#{@medium.embed_id}&color=%23ff5500&auto_play=false&hide_related=true&show_comments=false&show_user=false&show_reposts=false&show_teaser=false&visual=true&sharing=false"
    end

    def call
      @medium.embed = embed_url
      oembed = HTTParty.get(
        "https://soundcloud.com/oembed?url=https://api.soundcloud.com/tracks/#{@medium.embed_id}&format=json",
        format: :plain,
      )
      data = JSON.parse(oembed.body).deep_symbolize_keys
      @medium.title = data[:title]
      if data[:thumbnail_url]
        HTTParty.get(data[:thumbnail_url]).body
      else
        File.read(Rails.root.join('public/soundcloud.jpg'))
      end
    end
  end
end
