# frozen_string_literal: true

require 'uri'

# Model class for a tour.
class Tour < ContentBase
  include ActionView::Helpers::DateHelper
  include HtmlSanitizer
  include Searchable

  has_many :tour_stops, autosave: true, dependent: :destroy
  has_many :stops, -> { distinct }, through: :tour_stops
  has_many :tour_modes, autosave: true, dependent: :destroy
  has_many :modes, through: :tour_modes
  belongs_to :mode, default: -> { Mode.last }
  has_many :tour_media, dependent: :destroy
  has_many :media, through: :tour_media
  belongs_to :medium, optional: true
  belongs_to :map_icon, optional: true
  has_many :tour_flat_pages, dependent: :destroy
  has_many :flat_pages, through: :tour_flat_pages
  has_many :tour_authors, dependent: :destroy
  has_many :users, through: :tour_authors
  has_many :slugs, dependent: :delete_all
  has_one :map_overlay, dependent: :destroy
  has_many :voice_overs, dependent: :destroy

  belongs_to :theme, default: -> { Theme.first }

  enum :default_lng,
    {
      'en-US': 0,
      'fr-FR': 1,
      'de-DE': 2,
      'pl-PL': 3,
      'nl-NL': 4,
      'fi-FI': 5,
      'sv-SE': 6,
      'it-IT': 7,
      'es-ES': 8,
      'pt-PT': 9,
      'ru-RU': 10,
      'pt-BR': 11,
      'es-MX': 12,
      'zh-CN': 13,
      'zh-TW': 14,
      'ja-JP': 15,
      'ko-KR': 16,
    }

  validates :title, presence: true, uniqueness: { case_sensitive: false }
  # Only when a tour is being published, so tours that are already
  # published stay published and can still be edited.
  validate :images_have_alt_text, if: :publishing?
  validate :open_geographies_endpoint_allowed, if: -> { open_geographies_endpoint.present? && will_save_change_to_open_geographies_endpoint? }

  before_validation -> { self.mode ||= Mode.last }
  before_validation -> { self.theme ||= Theme.first }
  before_validation -> { self.title ||= 'untitled' }
  before_validation :update_saved_stop_order
  before_save :update_icon_colors
  before_save :calculate_duration
  before_save :check_url
  before_save :check_for_overlay
  before_save :check_published
  after_save :ensure_slug
  after_create :add_modes

  scope :published, -> { where(published: true) }
  scope :mapable, -> { where(is_geo: true) }
  scope :has_stops, -> { includes(:stops).where.not(stops: { id: nil }) }
  # Everything search_data touches, so building it doesn't fall into N+1s.
  # Attachments/blobs are needed for the media/icon/voice-over URLs.
  WITH_FILE = { file_attachment: :blob }.freeze
  scope :search_import, -> {
    includes(
      :slugs,
      :theme,
      :mode,
      { medium: WITH_FILE },
      { map_icon: WITH_FILE },
      { map_overlay: WITH_FILE },
      { voice_overs: WITH_FILE },
      { tour_modes: :mode },
      { tour_flat_pages: { flat_page: :tours } },
      { tour_media: { medium: WITH_FILE } },
      {
        tour_stops: [
          { map_icon: WITH_FILE },
          {
            stop: [
              :stop_slugs,
              :tours,
              { medium: WITH_FILE },
              { map_icon: WITH_FILE },
              { voice_overs: WITH_FILE },
              { stop_media: { medium: WITH_FILE } },
            ],
          },
        ],
      },
    )
  }

  def sanitized_description
    HtmlSanitizer.accessible(description)
  end

  def slug
    URI.encode_uri_component(title.parameterize_intl)
  end

  def tenant
    Apartment::Tenant.current
  end

  def tenant_title
    Apartment::Tenant.current.titleize
  end

  delegate :title, to: :theme, prefix: true

  def splash
    splash_medium = if medium.present?
      medium
    elsif tour_media.any?
      tour_media.min_by(&:position).medium
    elsif ordered_stops.any?
      first_stop_medium
    end

    if splash_medium&.file&.attached?
      return {
        title: splash_medium.title,
        caption: splash_medium.caption,
        url: splash_medium.search_data[:files][:desktop],
      }
    end

    { title: 'OpenTourBuilder', caption: 'OpenTourBuilderLogo', url: 'https://opentour.site/assets/images/otb-bg.png' }
  end

  def stop_count
    tour_stops.size
  end

  def bounds
    if map_overlay.present?
      box = RGeo::Cartesian::BoundingBox.create_from_points(
        RGeo::Geographic.spherical_factory.point(map_overlay.east.to_f, map_overlay.south.to_f),
        RGeo::Geographic.spherical_factory.point(map_overlay.west.to_f, map_overlay.north.to_f),
      )

      return {
        south: box.min_y - (box.y_span / 8),
        north: box.max_y + (box.y_span / 8),
        east: box.max_x + (box.x_span / 8),
        west: box.min_x - (box.x_span / 8),
        centerLat: box.center_y,
        centerLng: box.center_x,
      }
    end

    stops_bounds
  end

  # Bounds around the tour's stops, padded by an eighth on each side.
  def stops_bounds
    return if ordered_stops.empty?

    points = ordered_stops.map { |stop| RGeo::Geographic.spherical_factory.point(stop.lng, stop.lat) }
    box = RGeo::Cartesian::BoundingBox.create_from_points(points.pop, points.pop)
    points.each { |point| box.add(point) }

    {
      south: box.min_y - (box.y_span / 8),
      north: box.max_y + (box.y_span / 8),
      east: box.max_x + (box.x_span / 8),
      west: box.min_x - (box.x_span / 8),
      centerLat: box.center_y,
      centerLng: box.center_x,
    }
  end

  def calculate_duration
    return unless published

    return if stops.count < 2

    return if mode.nil?

    return if mode.title.nil?

    unless will_save_change_to_published? || will_save_change_to_saved_stop_order? || will_save_change_to_mode_id?
      return
    end

    waypoints = tour_stops.order(:position).map { |tour_stop| [tour_stop.stop.lat, tour_stop.stop.lng] }

    self.travel_duration = waypoints.each_cons(2).map do |origin, destination|
      GoogleDirections.new(origin, [destination], 1, mode.title.downcase).durations&.sum
    end.compact.sum

    # 3.3 is ~ 200 words per-minute, but we need it in seconds, so 200 / 60 = 3.3
    self.read_duration = stops.map { |stop| (stop.sanitized_description.split.size / 3.3).to_i }.sum

    self.duration = travel_duration + read_duration if travel_duration
  end

  def check_published
    if published? && published_on.nil?
      self.published_on = Time.current
    elsif !published?
      self.published_on = nil
    end
  end

  def search_data
    {
      blank_map:,
      bounds:,
      default_lng:,
      description:,
      flat_pages: tour_flat_pages.sort_by(&:position).map(&:search_data),
      icon_color:,
      id:,
      is_geo:,
      link_address:,
      link_text:,
      map_icon: map_icon&.original_image_url || nil,
      map_overlay: map_overlay&.search_data,
      map_type: map_type || 'hybrid',
      media: media_search_data(tour_media),
      meta_description: search_meta_description,
      mode: mode.search_data,
      modes: tour_modes.map(&:search_data),
      open_geographies_endpoint:,
      published:,
      published_on:,
      read_duration: [duration_in_words(read_duration), 'reading'].join(' '),
      restrict_bounds:,
      restrict_bounds_to_overlay:,
      sanitized_description:,
      splash:,
      slug:,
      slugs: slugs.map(&:slug),
      stop_count:,
      stops: begin
        sorted = tour_stops.sort_by(&:position)
        sorted.each_with_index.map do |ts, i|
          ts.search_data_with_neighbors(
            prev_stop: i > 0 ? sorted[i - 1].stop : nil,
            next_stop: sorted[i + 1]&.stop,
          )
        end
      end,
      tenant:,
      tenant_title:,
      title:,
      travel_duration: [duration_in_words(travel_duration), mode.title.downcase].join(' '),
      theme: { id: theme.id, title: theme.title },
      type: 'tour',
      voice_overs: voice_overs.map(&:search_data),
      use_directions:,
    }
  end

  private

  def ensure_slug
    tour_slug = title.parameterize_intl
    existing = Slug.find_by(slug: tour_slug)

    if existing
      existing.update(tour: self) unless existing.tour == self
    else
      slugs.create(slug: tour_slug)
    end
  end

  def add_modes
    Mode.all.find_each do |m|
      modes << m
    end
  end

  def check_url
    return if link_address.blank?

    uri = URI(link_address)

    self.link_address = "http://#{link_address}" if uri.scheme.nil?
  end

  def update_saved_stop_order
    self.saved_stop_order = tour_stops.order(:position).map(&:stop_id)
  end

  def check_for_overlay
    # Can't restrict to overlay without an overlay present
    if restrict_bounds_to_overlay? && map_overlay.nil?
      self.restrict_bounds_to_overlay = false
      return
    end

    # These two flags are mutually exclusive — the most recently changed one wins
    if restrict_bounds_to_overlay_changed? && restrict_bounds_to_overlay?
      self.restrict_bounds = false
    elsif restrict_bounds_changed? && restrict_bounds?
      self.restrict_bounds_to_overlay = false
    end
  end

  def search_meta_description
    return meta_description unless meta_description.nil?

    sanitized_description
  end

  def first_stop_medium
    ordered_stops.each do |stop|
      first = stop.stop_media.min_by(&:position)
      return first.medium if first
    end
    nil
  end

  # Stops in tour order, built from the (preloadable) tour_stops rather than
  # the `stops` through-association, which would query again.
  def ordered_stops
    tour_stops.sort_by(&:position).map(&:stop)
  end

  def duration_in_words(dur)
    return if dur.nil? || dur.zero?

    distance_of_time_in_words(dur).capitalize
  end

  def update_icon_colors
    if will_save_change_to_icon_color?
      old_value, new_value = icon_color_change_to_be_saved
      tour_stops.each do |ts|
        # It should only sync the TourStop icon color if it
        # currently the same as the Tour's.
        next if ts.icon_color != old_value

        ts.update(icon_color: new_value)
      end
    end
  end

  # Images in the tour and its stops with no alt text that aren't decorative.
  def media_missing_alt_text
    via_stops = StopMedium.where(stop_id: tour_stops.select(:stop_id)).select(:medium_id)
    Medium.where(id: tour_media.select(:medium_id)).or(Medium.where(id: via_stops)).missing_alt_text
  end

  def publishing?
    will_save_change_to_published? && published? && !published_in_database
  end

  def images_have_alt_text
    missing = media_missing_alt_text.count
    return if missing.zero?

    errors.add(
      :published,
      "can't be turned on until every image has alt text of at least #{Medium::MIN_ALT_TEXT_WORDS} words or is marked decorative " \
        "(#{missing} #{missing == 1 ? "image needs" : "images need"} it).",
    )
  end

  def open_geographies_endpoint_allowed
    problem = OpenGeographies::Source.url_problem(open_geographies_endpoint)
    errors.add(:open_geographies_endpoint, problem) if problem
  end
end
