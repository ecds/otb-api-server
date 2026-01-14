# frozen_string_literal: true

require 'uri'

# Model class for a tour.
class Tour < ApplicationRecord
  include ActionView::Helpers::DateHelper
  include HtmlSanitizer
  include Searchable
  
  has_many :tour_stops, autosave: true, dependent: :destroy
  has_many :stops, -> { distinct }, through: :tour_stops
  has_many :tour_modes, autosave: true, dependent: :destroy
  has_many :modes, through: :tour_modes
  belongs_to :mode, default: -> { Mode.last }
  has_many :tour_media
  has_many :media, through: :tour_media
  belongs_to :medium, optional: true
  has_many :tour_flat_pages
  has_many :flat_pages, through: :tour_flat_pages
  has_many :tour_authors
  has_many :users, through: :tour_authors
  has_many :slugs, dependent: :delete_all
  has_one :map_overlay

  # TODO: why does the CircleCI env need to serialize here?
  if ENV['CI'] == 'circleci'
    serialize :saved_stop_order, Array
  end

  # belongs_to :splash_image_medium_id, class_name: 'Medium'
  belongs_to :theme, default: -> { Theme.first }

  enum default_lng: {
    "en-US": 0, "fr-FR": 1, "de-DE": 2, "pl-PL": 3, "nl-NL": 4, "fi-FI": 5, "sv-SE": 6, "it-IT": 7, "es-ES": 8, "pt-PT": 9,
    "ru-RU": 10, "pt-BR": 11, "es-MX": 12, "zh-CN": 13, "zh-TW": 14, "ja-JP": 15, "ko-KR": 16
  }

  validates :title, presence: true, uniqueness: { case_sensitive: false }

  before_validation -> { self.mode ||= Mode.last }
  before_validation -> { self.theme ||= Theme.first }
  before_validation -> { self.title ||= 'untitled' }
  before_validation :update_saved_stop_order
  before_save :calculate_duration
  before_save :check_url
  before_save :check_for_overlay
  after_save :ensure_slug
  after_create :add_modes

  scope :published, -> { where(published: true) }
  scope :mapable, -> { where(is_geo: true) }
  scope :has_stops, -> { includes(:stops).where.not(stops: { id: nil }) }

  def sanitized_description
    HtmlSanitizer.accessible(description)
  end

  def slug
    title.parameterize_intl
  end

  def tenant
    Apartment::Tenant.current
  end

  def tenant_title
    Apartment::Tenant.current.titleize
  end

  def theme_title
    theme.title
  end

  def splash
    splash_medium = if medium.present?
      medium
    elsif tour_media.present?
      tour_media.order(:position).first.medium
    else
      nil
    end

    if splash_medium
      return { title: splash_medium.title, caption: splash_medium.caption, url: splash_medium.files[:desktop] }
    end
    nil
  end

  def stop_count
    self.stops.count
  end

  def bounds
    if self.restrict_bounds_to_overlay && self.map_overlay.present?
      box = RGeo::Cartesian::BoundingBox.create_from_points(
        RGeo::Geographic.spherical_factory.point(self.map_overlay.east.to_f, self.map_overlay.south.to_f),
        RGeo::Geographic.spherical_factory.point(self.map_overlay.west.to_f, self.map_overlay.north.to_f)
      )

      return {
        south: box.min_y - (box.y_span / 8),
        north: box.max_y + (box.y_span / 8),
        east: box.max_x + (box.x_span / 8),
        west: box.min_x - (box.x_span / 8),
        centerLat: box.center_y,
        centerLng: box.center_x
      }
    elsif stops.empty?
      return nil
    end

    points = stops.map { |stop| RGeo::Geographic.spherical_factory.point(stop.lng, stop.lat) }
    box = RGeo::Cartesian::BoundingBox.create_from_points(points.pop, points.pop)
    points.each { |point| box.add(point) }

    {
      south: box.min_y - (box.y_span / 8),
      north: box.max_y + (box.y_span / 8),
      east: box.max_x + (box.x_span / 8),
      west: box.min_x - (box.x_span / 8),
      centerLat: box.center_y,
      centerLng: box.center_x
    }
  end

  def calculate_duration
    return unless published

    return if stops.count < 2

    return if mode.nil?

    return if mode.title.nil?

    return unless self.will_save_change_to_published? || self.will_save_change_to_saved_stop_order? || self.will_save_change_to_mode_id?

    durations = []
    destinations = tour_stops.order(:position).map { |tour_stop| [tour_stop.stop.lat, tour_stop.stop.lng] }

    # The direction matrix API limits the number of destinations to 25.
    # Calculate the duration in chunks to stay below the limit.
    destinations.each_slice(24) do |group|
      origin = group.shift
      g_directions = GoogleDirections.new(origin, group, group.count + 1, mode.title)
      durations.push(g_directions.duration)
    end

    self.duration = durations.compact.sum.zero? ? nil : durations.sum
  end

  def search_data
    {
      blank_map:,
      bounds:,
      default_lng:,
      description:,
      est_time: duration ? "#{distance_of_time_in_words(duration).capitalize} #{mode.title.downcase}" : nil,
      flat_pages: tour_flat_pages.map { |fp| {title: fp.flat_page.title, position: fp.position, slug: fp.flat_page.slug, body: fp.flat_page.body} }.sort_by { |fp| fp[:position] },
      id:,
      is_geo:,
      link_address:,
      link_text:,
      map_overlay: map_overlay_index,
      map_type: map_type || 'hybrid',
      media: media_index,
      modes: modes.map { |m| {title: m.title, icon: m.icon, default: m == self.mode } },
      published:,
      restrict_bounds:,
      restrict_bounds_to_overlay:,
      sanitized_description:,
      splash:,
      slug:,
      stop_count:,
      stops: stop_index,
      tenant:,
      tenant_title:,
      title:,
      theme: theme.title,
      type: 'tour',
      use_directions:
    }
  end

  private

    def ensure_slug
      Slug.find_or_create_by(slug: self.slug, tour: self)
    end

    def add_modes
      Mode.all.each do |m|
        self.modes << m
      end
    end

    def check_url
      return if link_address.blank?

      uri = URI(link_address)

      self.link_address = "http://#{link_address}" if uri.scheme.nil?
    end

    def update_saved_stop_order
      self.saved_stop_order = self.tour_stops.order(:position).map(&:stop_id)
    end

    def check_for_overlay
      if self.restrict_bounds_to_overlay && self.map_overlay.nil?
        self.restrict_bounds_to_overlay = false
        # self.restrict_bounds = false
      end

      if !self.restrict_bounds_to_overlay_was && self.restrict_bounds_to_overlay && self.map_overlay.present?
        self.restrict_bounds = false
      end

      if self.restrict_bounds && !self.restrict_bounds_was
        self.restrict_bounds_to_overlay = false
      end
    end

    def media_index
      indexed_media = tour_media.map do |m|
        medium_index(m, tenant)
      end
      
      indexed_media.sort_by { |m| m[:position] }
    end

    def stop_index
      indexed_stops = tour_stops.map do |ts|
        {
          next: ts.next.present? ? { id: ts.next.stop.id, slug: ts.next.stop.slug, title: ts.next.stop.title } : nil,
          position: ts.position,
          previous: ts.previous.present? ? { id: ts.previous.stop.id, slug: ts.previous.stop.slug, title: ts.previous.stop.title } : nil,
          **ts.stop.search_data
        }
      end
      
      return indexed_stops.sort_by { |s| s[:position] }
    end

    def map_overlay_index
      return unless map_overlay.present?
      
      return {
        east: map_overlay.east,
        image_url: map_overlay.original_image_url,
        north: map_overlay.north,
        south: map_overlay.south,
        west: map_overlay.west
      }
    end
end
