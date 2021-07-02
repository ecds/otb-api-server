# frozen_string_literal: true

# Model for media associated with stops.
class Medium < MediumBaseRecord
  include VideoProps
  include Rails.application.routes.url_helpers
  before_create :props
  before_update :remove_tmp_file

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



  # TODO: This is not ideal, we use these `not_in_*` scopes to make the list of media avaliable to add
  # to a stop or tour. But the paramerter does not make sense when just looking at it. Needs clearer language.
  scope :not_in_stop, lambda { |stop_id| includes(:stop_media).where.not(stop_media: { stop_id: stop_id }) }
  scope :not_in_tour, lambda { |tour_id| includes(:tour_media).where.not(tour_media: { tour_id: tour_id }) }
  scope :no_stops, lambda { includes(:stop_media).where(stop_media: { stop_id: nil }) }
  scope :no_tours, lambda { includes(:tour_media).where(tour_media: { tour_id: nil }) }
  scope :orphan, -> { no_tours.no_stops }
  scope :published_by_tour, lambda { includes(:tours).where(tours: { published: true }) }
  scope :published_by_stop, -> { joins(:stops).merge(Stop.published) }


  def props
    return if self.video.nil? || self.video.empty?

    VideoProps.props(self)
  end

  # def desktop
  #   original_image.desktop.url
  # end

  # def tablet
  #   original_image.tablet.url
  # end

  # def mobile
  #   original_image.mobile_list_thumb.url
  # end

  # def mobile_thumb
  #   original_image.mobile_list_thumb.url
  # end

  def published
    # This works and is shorter, but I think the longer way is more readable/clear.
    # tours.published.present? || stops { |s| s.tours.published }.present?
    tours.collect(&:published).include?(true) || stops.map { |s| s.tours.collect(&:published) }.flatten.include?(true)
  end

  def files
    return nil if !self.file.attached?
    {
      mobile: "#{ENV['BASE_URL']}/#{Apartment::Tenant.current}/media/#{id}/file?context=mobile",
      tablet: "#{ENV['BASE_URL']}/#{Apartment::Tenant.current}/media/#{id}/file?context=tablet",
      desktop: "#{ENV['BASE_URL']}/#{Apartment::Tenant.current}/media/#{id}/file?context=desktop"
    }
  end

  def srcset
    nil
    # "#{ENV['BASE_URL']}#{self.mobile} #{mobile_width}w, \
    # #{ENV['BASE_URL']}#{self.tablet} #{tablet_width}w, \
    # #{ENV['BASE_URL']}#{self.desktop} #{desktop_width}w"
  end

  def srcset_sizes
    "(max-width: 680px) #{mobile_width}px, (max-width: 880px) #{tablet_width}px, #{desktop_width}px"
  end

  def insecure
    nil
    # "#{ENV['INSECURE_IMAGE_BASE_URL']}#{self.desktop}"
  end

  # def base64
  #   if self.original_image.file && File.file?(self.original_image.file.path)
  #     return Base64.encode64(self.original_image.file.read)
  #   end
  #   nil
  # end
end
