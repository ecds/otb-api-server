# frozen_string_literal: true

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

  enum video_provider: { keiner: 0, vimeo: 1, youtube: 2, soundcloud: 3 }

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

    if file.content_type.include?('gif')
      height = ActiveStorage::Analyzer::ImageAnalyzer.new(file).metadata[:height]
      return {
        lqip: file.variant(resize_to_limit: [50, 50], coalesce: true, layers: 'Optimize', deconstruct: true, loader: { page: nil }).processed.url,
        mobile: file.variant(resize_to_limit: [300, 300], coalesce: true, layers: 'Optimize', deconstruct: true, loader: { page: nil }).processed.url,
        tablet: file.variant(resize_to_limit: [400, 400], coalesce: true, layers: 'Optimize', deconstruct: true, loader: { page: nil }).processed.url,
        desktop: file.variant(resize_to_limit: [750, 750], coalesce: true, layers: 'Optimize', deconstruct: true, loader: { page: nil }).processed.url
      }
    end
    {
      lqip: file.variant(resize_to_limit: [5, 5]).processed.url,
      mobile: file.variant(resize_to_limit: [300, 300]).processed.url,
      tablet: file.variant(resize_to_limit: [400, 400]).processed.url,
      desktop: file.variant(resize_to_limit: [750, 750]).processed.url
    }
  end

  def orphaned
    tours.empty? && stops.empty?
  end

  def replace_video
    if video.present? && base_sixty_four.present?
      attach_file
    end
  end

  def add_widths
    return unless file.attached?

    self.lqip_width = MiniMagick::Image.open(files[:lqip])[:width] || 50
    self.mobile_width = MiniMagick::Image.open(files[:mobile])[:width] || 300
    self.tablet_width = MiniMagick::Image.open(files[:tablet])[:width] || 400
    self.desktop_width = MiniMagick::Image.open(files[:desktop])[:width] || 750
  end
end
