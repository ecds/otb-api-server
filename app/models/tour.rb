# frozen_string_literal: true

require 'google_maps_service'
require 'uri'

# Model class for a tour.
class Tour < ApplicationRecord
  include HtmlSaintizer
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

  # belongs_to :splash_image_medium_id, class_name: 'Medium'
  belongs_to :theme, default: -> { Theme.first }

  enum default_lng: {
    en: 0, fr: 1, de: 2, pl: 3, nl: 4, fi: 5, sv: 6, it: 7, es: 8, pt: 9,
    ru: 10, "pt-BR": 11, "es-MX": 12, "zh-CN": 13, "zh-TW": 14, ja: 15, ko: 16
  }

  validates :title, presence: true

  before_validation -> { self.mode ||= Mode.last }
  before_validation -> { self.theme ||= Theme.first }
  before_validation -> { self.title ||= 'untitled' }
  before_save :check_url
  after_save :ensure_slug
  after_create :add_modes

  scope :published, -> { where(published: true) }
  scope :mapable, -> { where(is_geo: true) }
  scope :has_stops, -> { includes(:stops).where.not(stops: { id: nil }) }

  def sanitized_description
    HtmlSaintizer.accessable(description)
  end

  def slug
    title.parameterize
  end

  def tenant
    Apartment::Tenant.current
  end

  def tenant_title
    Apartment::Tenant.current.titleize
  end

  # def external_url
  #   if Apartment::Tenant.current == 'public'
  #     return nil
  #   end
  #   TourSet.find_by(subdir: Apartment::Tenant.current).external_url
  # end

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

  def insecure_splash
    # if !tour_media.empty?
    #   return medium.nil? ? tour_media.order(:position).first.medium.insecure : medium.insecure
    # end
    nil
  end

  def stop_count
    self.stops.count
  end

  def bounds
    return nil if stops.empty?

    points = stops.map { |stop| RGeo::Geographic.spherical_factory.point(stop.lng, stop.lat) }
    box = RGeo::Cartesian::BoundingBox.create_from_points(points.pop, points.pop)
    points.each { |point| box.add(point) }

    {
      south: box.min_y,
      north: box.max_y,
      east: box.max_x,
      west: box.min_x,
      centerLat: box.center_y,
      centerLng: box.center_x
    }
  end

  def duration
    return nil if stops.count < 2

    return nil if mode.nil?

    return nil if mode.title.nil?

    gmaps = GoogleMapsService::Client.new
    destinations = tour_stops.order(:position).map { |tour_stop| [tour_stop.stop.lat, tour_stop.stop.lng] }
    origin = destinations.shift

    begin
      matrix = gmaps.distance_matrix(origin, destinations, mode: mode.title.downcase)
      return nil if matrix[:rows].first[:elements].first[:status] == 'ZERO_RESULTS'

      durations = matrix[:rows].first[:elements].map { |e| e[:duration][:value] if e[:duration].present? }.reject { |d| d.nil? }
      durations.sum + 600 + (stops.count * 600)
      # ActiveSupport::Duration.build(seconds).parts
    rescue GoogleMapsService::Error::ApiError, ArgumentError => error
      nil
    end
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
      return if link_address.nil?

      uri = URI(link_address)

      self.link_address = "http://#{link_address}" if uri.scheme.nil?
    end
end
