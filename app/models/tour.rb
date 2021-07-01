# frozen_string_literal: true

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
  has_many :authors, through: :tour_authors, source: :user
  has_many :slugs, dependent: :delete_all
  has_one :map_overlay
  # has_many :authors, through: :tour_authors, foreign_key: :user_id

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
  after_save :ensure_slug
  after_create :add_modes

  scope :published, -> { where(published: true) }

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
    if medium.present?
      return medium
    elsif tour_media.present?
      return tour_media.order(:position).first.medium
    end
    nil
  end

  def splash_url
    return if splash.nil?

    splash.files[:desktop]
  end

  def splash_height
    splash.nil? ? nil : splash.desktop_height
  end

  def splash_width
    splash.nil? ? nil : splash.desktop_width
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

    points = stops.map { |s| RGeo::Geographic.spherical_factory.point(s.lng, s.lat) }
    box = RGeo::Cartesian::BoundingBox.create_from_points(points.pop, points.pop)
    points.each { |p| box.add(p) }

    {
      south: box.min_y,
      north: box.max_y,
      east: box.max_x,
      west: box.min_x,
      centerLat: box.center_y,
      centerLng: box.center_x
    }
  end

  private

    def ensure_slug
      new_slug = Slug.find_or_create_by(slug: self.slug)
      new_slug.tour = self
      new_slug.save
    end

    def add_modes
      Mode.all.each do |m|
        self.modes << m
      end
    end
end
