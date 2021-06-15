class V3::MapOverlaySerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  attributes :id, :south, :north, :east, :west, :image_url, :title

  def image_url
    return nil unless object.public_send("#{Apartment::Tenant.current.underscore}_file").attached?
    rails_blob_url(object.public_send("#{Apartment::Tenant.current.underscore}_file"))
  end
end
