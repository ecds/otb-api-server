# frozen_string_literal: true

module EmbedProps
  extend ActiveSupport::Concern

  PROVIDERS = {
    'youtube' => VideoProviders::Youtube,
    'vimeo' => VideoProviders::Vimeo,
    'soundcloud' => VideoProviders::Soundcloud,
    'sketchfab' => VideoProviders::Sketchfab,
    'matterport' => VideoProviders::Matterport,
    'morphosource' => VideoProviders::Morphosource,
  }.freeze

  class << self
    def props(medium)
      return if medium.embed_id.blank? || medium.video_provider == 'keiner'

      provider_class = PROVIDERS.fetch(medium.video_provider, VideoProviders::Base)
      downloaded_image = provider_class.new(medium).call
      return if downloaded_image.nil?

      medium.filename ||= "#{medium.embed_id}.jpg"
      medium.base_sixty_four = Base64.encode64(downloaded_image)
      medium.attach_file unless medium.file.attached?
      # TODO: remove this on release of V4.
      medium.video = medium.embed_id
    end
  end
end
