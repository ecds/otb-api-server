# frozen_string_literal: true

# Model for media associated with stops.
class Medium < MediumBaseRecord
  include VideoProps
  include Rails.application.routes.url_helpers
  before_create :props
  before_update :replace_video

  # has_one_attached :file do |attachable|
  #   attachable.variant :mobile, resize: '200x200'
  #   attachable.variant :tablet, resize: '300x300'
  #   attachable.variant :desktop, resize: '750x750'
  # end

  mount_base64_uploader :original_image, MediumUploader
  has_many :stop_media
  has_many :stops, through: :stop_media
  has_many :tour_media
  has_many :tours, through: :tour_media

  enum video_provider: { keiner: 0, vimeo: 1, youtube: 2, soundcloud: 3 }

  # validates_presence_of :original_image

  attr_accessor :insecure

  def props
    return if self.video.nil? || self.video.empty?

    VideoProps.props(self)
  end

  def published
    tours.any? { |tour| tour.published } || stops.any? { |stop| stop.published }
  end

  def files
    return nil if !self.file.attached?
    begin
      {
        mobile: file.variant(resize: '300x300').processed.service_url,
        tablet: file.variant(resize: '400x400').processed.service_url,
        desktop: file.variant(resize: '750x750').processed.service_url
      }
    rescue ActiveStorage::FileNotFoundError => error
      { mobile: nil, tablet: nil, desktop: nil }
    end
  end

  def orphaned
    tours.empty? && stops.empty?
  end

  def srcset
    nil
    # "#{ENV['BASE_URL']}#{self.mobile} #{mobile_width}w, \
    # #{ENV['BASE_URL']}#{self.tablet} #{tablet_width}w, \
    # #{ENV['BASE_URL']}#{self.desktop} #{desktop_width}w"
  end

  def srcset_sizes
    nil
    # "(max-width: 680px) #{mobile_width}px, (max-width: 880px) #{tablet_width}px, #{desktop_width}px"
  end

  def insecure
    nil
    # "#{ENV['INSECURE_IMAGE_BASE_URL']}#{self.desktop}"
  end

  def replace_video
    if video.present? && base_sixty_four.present?
      attach_file
    end
  end
end
