# frozen_string_literal: true

module OpenGeographies
  # Turns an Open Geographies media embed_url into what a natively added
  # medium has: the provider, its id for the item, and an iframe URL, all
  # from the same VideoProviders classes (page URLs like youtube.com/watch
  # can't be shown in an iframe).
  module Embed
    class << self
      # { provider:, embed_id:, embed: }, or nil when there's nothing to embed.
      def call(embed_url)
        url = embed_url.to_s.strip
        return unless url.match?(%r{\Ahttps?://}i)

        provider = VideoProviders.detect(url)
        provider_class = VideoProviders.class_for(provider)
        embed_id = provider && provider_class.embed_id_from(url)

        if embed_id
          embed = provider_class.new(VideoProviders::Item.new(embed_id)).embed_url
          { provider:, embed_id:, embed: }
        elsif provider == 'soundcloud'
          # SoundCloud's player takes any SoundCloud page URL.
          { provider:, embed_id: nil, embed: "//w.soundcloud.com/player/?url=#{CGI.escape(url)}&visual=true" }
        else
          { provider:, embed_id: nil, embed: url }
        end
      end
    end
  end
end
