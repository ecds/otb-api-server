# frozen_string_literal: true

module VideoProviders
  class Morphosource < Base
    def embed_url
      "//www.morphosource.org/uv.html#?manifest=/manifests/#{@medium.embed_id}&c=0&m=0&cv=0"
    end

    def call
      @medium.embed = embed_url
      manifest = HTTParty.get("https://www.morphosource.org/manifests/#{@medium.embed_id}.json")
      @medium.title = manifest.dig('label', '@none', 0) || 'A MorphoSource Model'
      @medium.caption = manifest.dig('summary', '@none', 0)
      @medium.filename ||= 'otblogo.png'
      File.read(Rails.root.join('public/otblogo.png'))
    end
  end
end
