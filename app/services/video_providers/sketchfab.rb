# frozen_string_literal: true

module VideoProviders
  class Sketchfab < Base
    def embed_url
      "//sketchfab.com/models/#{@medium.embed_id}/embed"
    end
  end
end
