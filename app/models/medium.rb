# frozen_string_literal: true

require 'cgi'

# Model for media associated with stops.
class Medium < MediumBaseRecord
  include VideoProps
  include Rails.application.routes.url_helpers

  before_create :props
  before_save :add_widths
  before_update :replace_video

  # has_one_attached :file do |attachable|
  #   attachable.variant :mobile, resize: '200x200'
  #   attachable.variant :tablet, resize: '300x300'
  #   attachable.variant :desktop, resize: '750x750'
  # end

  # mount_base64_uploader :original_image, MediumUploader
  has_many :stop_media
  has_many :stops, through: :stop_media
  has_many :tour_media
  has_many :tours, through: :tour_media

  enum :video_provider, { keiner: 0, vimeo: 1, youtube: 2, soundcloud: 3 }
  attr_accessor :insecure

  def props
    return if video.blank?

    VideoProps.props(self)
  end

  def published
    tours.any?(&:published) || stops.any?(&:published)
  end

  def files
    return unless file.attached?

    if file.content_type.include?('gif')
      return {
        lqip: file.url,
        mobile: file.url,
        tablet: file.url,
        desktop: file.url,
      }
    end
    {
      lqip: file.variant(resize_to_limit: [5, 5]).processed.url,
      mobile: file.variant(resize_to_limit: [300, 300]).processed.url,
      tablet: file.variant(resize_to_limit: [400, 400]).processed.url,
      desktop: file.variant(resize_to_limit: [750, 750]).processed.url,
    }
  end

  def orphaned
    tours.empty? && stops.empty?
  end

  def search_data
    http_path = "#{Rails.application.routes.default_url_options[:host]}/#{Apartment::Tenant.current}/v4/public/media/#{CGI.escape(file.key || "")}"
    {
      caption:,
      desktop_width:,
      embed:,
      filename:,
      files: {
        original: http_path,
        mobile: "#{http_path}?variant=mobile",
        tablet: "#{http_path}?variant=tablet",
        desktop: "#{http_path}?variant=desktop",
        lqip: "#{http_path}?variant=lqip",
      },
      id: id,
      lqip_width:,
      mobile_width:,
      original_image:,
      provider:,
      tablet_width:,
      title:,
      video:,
    }
  end

  private

  def replace_video
    return if video.blank?

    attach_file
  end

  def add_widths
    return unless file.attached?

    self.lqip_width = 50
    self.mobile_width = 300
    self.tablet_width = 400
    self.desktop_width = 750
  end
end
