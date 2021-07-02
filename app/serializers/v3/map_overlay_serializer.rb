class V3::MapOverlaySerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  attributes :id, :south, :north, :east, :west, :image_url, :title

  def image_url
    return nil unless object.file.attached?
    rails_blob_url(object.file)
  end
end
