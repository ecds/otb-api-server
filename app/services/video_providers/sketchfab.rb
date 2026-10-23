# frozen_string_literal: true

module VideoProviders
  class Sketchfab < Base
    EMBED_ID = %r{sketchfab\.com/(?:3d-)?models/(?:[^/?#]*-)?([0-9a-f]{32})}i

    def embed_url
      "//sketchfab.com/models/#{@medium.embed_id}/embed"
    end
  end
end
