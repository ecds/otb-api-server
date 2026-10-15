# frozen_string_literal: true

module V3
  class MapIconSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers
    attributes :id, :base_sixty_four, :filename, :original_image_url
  end
end
