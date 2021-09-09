class V3::MapOverlaySerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  attributes :id, :south, :north, :east, :west, :original_image_url, :filename
end
