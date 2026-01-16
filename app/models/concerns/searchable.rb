# frozen_string_literal: true

# Common stuff for indexing
module Searchable
  extend ActiveSupport::Concern

  included do
    searchkick index_name: -> { "otb_#{Apartment::Tenant.current}_#{model_name.plural}_#{Rails.env}" },
    callbacks: false,
    deep_paging: true

    after_commit :reindex_record
  end

  def medium_index(m, current_tenant)
    http_path = "#{Rails.application.routes.default_url_options[:host]}/#{current_tenant}/v4/public/media/#{m.medium.file.key}"
    {
      caption: m.medium.caption,
      desktop_width: m.medium.desktop_width,
      embed: m.medium.embed,
      filename: m.medium.filename,
      files: {
        original: http_path,
        mobile: "#{http_path}?variant=mobile",
        tablet: "#{http_path}?variant=tablet",
        desktop: "#{http_path}?variant=desktop",
        lqip: "#{http_path}?variant=lqip"
      },
      id: m.medium.id,
      lqip_width: m.medium.lqip_width,
      mobile_width: m.medium.mobile_width,
      original_image: m.medium.original_image,
      position: m.position,
      provider: m.medium.provider,
      tablet_width: m.medium.tablet_width,
      title: m.medium.title,
      video: m.medium.video
    }
  end

  private

  def reindex_record
    ReindexJob.perform_later(tenant: Apartment::Tenant.current, class_name: self.class.name, id:)
  end
end
