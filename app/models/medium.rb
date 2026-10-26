# frozen_string_literal: true

require 'cgi'

# Model for media associated with stops.
class Medium < MediumBaseRecord
  include EmbedProps
  include Rails.application.routes.url_helpers

  ALLOWED_CONTENT_TYPES = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
  ].freeze

  validates :file, content_type: { in: ALLOWED_CONTENT_TYPES }

  # TODO: get rid of VideoProps after next release.
  before_create :v_props
  before_create :props
  before_save :add_widths
  before_update :replace_video
  after_create_commit -> { ProcessMediumVariantsJob.perform_later(tenant: Apartment::Tenant.current, id:) }

  VARIANT_SIZES = {
    lqip: [5, 5],
    mobile: [300, 300],
    tablet: [400, 400],
    desktop: [750, 750],
  }.freeze

  # has_one_attached :file do |attachable|
  #   attachable.variant :mobile, resize: '200x200'
  #   attachable.variant :tablet, resize: '300x300'
  #   attachable.variant :desktop, resize: '750x750'
  # end

  # mount_base64_uploader :original_image, MediumUploader
  has_many :stop_media, dependent: :destroy
  has_many :stops, through: :stop_media
  has_many :tour_media, dependent: :destroy
  has_many :tours, through: :tour_media

  # Not in any tour's or stop's media, and not a tour's or stop's main image.
  scope :unused, lambda {
    where.not(id: TourMedium.select(:medium_id))
      .where.not(id: StopMedium.select(:medium_id))
      .where.not(id: Tour.where.not(medium_id: nil).select(:medium_id))
      .where.not(id: Tour.where.not(splash_image_medium_id: nil).select(:splash_image_medium_id))
      .where.not(id: Stop.where.not(medium_id: nil).select(:medium_id))
  }

  # No alt text, and not marked decorative.
  scope :missing_alt_text, -> { where(decorative: false).where("coalesce(trim(alt_text), '') = ''") }

  # Media used by the tour itself or by any of its stops. A subquery rather
  # than joins, so it can be paginated without duplicate rows.
  scope :used_in_tour, lambda { |tour_id|
    stop_ids = TourStop.where(tour_id:).select(:stop_id)
    where(id: TourMedium.where(tour_id:).select(:medium_id))
      .or(where(id: StopMedium.where(stop_id: stop_ids).select(:medium_id)))
  }

  enum :video_provider, { keiner: 0, vimeo: 1, youtube: 2, soundcloud: 3, sketchfab: 4, unknown: 5, matterport: 6, morphosource: 7 }
  attr_accessor :insecure

  def v_props
    return if embed_id.present? || video.blank?

    VideoProps.props(self)
  end

  def props
    return if embed_id.blank?

    EmbedProps.props(self)
  end

  def published
    tours.any?(&:published) || stops.any?(&:published)
  end

  def files
    return unless file.attached?

    VARIANT_SIZES.keys.index_with { |name| variant_url(name, process: false) }
  end

  # URL for a named variant. With process: true a missing variant is generated
  # on the spot, so media whose background processing never ran still render.
  def variant_url(name, process: true)
    return unless file.attached?
    return file.url if file.content_type.include?('gif')

    size = VARIANT_SIZES[name.to_sym]
    return if size.nil?

    variant = file.variant(resize_to_limit: size)
    process ? variant.processed.url : variant.url
  end

  # Inlines the tiny lqip variant as a data URI so a gallery can show a
  # placeholder without waiting on another request. GIFs have no variants.
  def store_lqip_data!
    return unless file.attached?
    return if file.content_type.include?('gif')

    variant = file.variant(resize_to_limit: VARIANT_SIZES[:lqip]).processed
    content_type = variant.image.blob.content_type
    update!(lqip_data: "data:#{content_type};base64,#{Base64.strict_encode64(variant.download)}")
    reindex_tours if saved_change_to_lqip_data?
  end

  # Tours that show this medium, directly or through one of their stops.
  def tours_using
    via_stops = TourStop.where(stop_id: stop_media.select(:stop_id)).select(:tour_id)
    Tour.where(id: tour_media.select(:tour_id)).or(Tour.where(id: via_stops))
  end

  def orphaned
    tours.empty? && stops.empty?
  end

  # Tours that use this medium, directly or through one of their stops.
  # Preload tours and stops: :tours when listing many media.
  def appears_in
    (tours + stops.flat_map(&:tours)).uniq(&:id).map { |tour| { id: tour.id, title: tour.title } }
  end

  # No description for screen readers, and not marked decorative.
  def missing_alt_text?
    alt_text.blank? && !decorative?
  end

  def search_data
    {
      alt_text:,
      caption:,
      decorative:,
      missing_alt_text: missing_alt_text?,
      desktop_width:,
      embed:,
      embed_id:,
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
      provider: provider || video_provider,
      tablet_width:,
      title:,
      video:,
    }
  end

  private

  # Tour search data embeds media (and the first one's lqip_data), but Medium
  # isn't indexed itself, so nothing else would pick the change up.
  def reindex_tours
    tours_using.pluck(:id).each do |tour_id|
      ReindexJob.perform_later(tenant: Apartment::Tenant.current, class_name: 'Tour', id: tour_id)
    end
  end

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
