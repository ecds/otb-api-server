# frozen_string_literal: true

module EmbedProps
  extend ActiveSupport::Concern

  class << self
    def props(medium)
      return if medium.embed_id.blank? || medium.video_provider == 'keiner'

      provider_class = VideoProviders.class_for(medium.video_provider)
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
