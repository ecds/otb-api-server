class V3::MapIconSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  attributes :id, :base_sixty_four, :title, :image_url

  def image_url
    return nil unless object.file.attached?
    rails_blob_url(object.file)
  end
end
