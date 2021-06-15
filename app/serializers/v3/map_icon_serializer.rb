class V3::MapIconSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  attributes :id, :base_sixty_four, :title, :image_url

  def image_url
    return nil unless object.public_send("#{Apartment::Tenant.current.underscore}_file").attached?
    rails_blob_url(object.public_send("#{Apartment::Tenant.current.underscore}_file"))
  end
end
