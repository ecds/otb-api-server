# frozen_string_literal: true

class V3::MediumSerializer < ActiveModel::Serializer
  # include Rails.application.routes.url_helpers
  attributes :id,
             :title,
             :caption,
             :video,
             :provider,
             :original_image,
             :embed,
             :srcset,
             :srcset_sizes,
             :insecure,
             :files,
             :orphaned,
             :filename,
             :original_image_url,
             :lqip_width,
             :mobile_width,
             :tablet_width,
             :desktop_width

  # def files
  #   return nil unless object.file.attached?
  #   {
  #     mobile: Rails.application.routes.url_helpers.rails_representation_url(object.file.variant(resize: '200x200').processed),
  #     tablet: Rails.application.routes.url_helpers.rails_representation_url(object.file.variant(resize: '300x300').processed),
  #     desktop: Rails.application.routes.url_helpers.rails_representation_url(object.file.variant(resize: '750x750').processed)
  #   }
  # end
end
