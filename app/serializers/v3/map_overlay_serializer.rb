module V3
  class MapOverlaySerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers
    attributes :id, :south, :north, :east, :west, :original_image_url, :filename
  end
end
