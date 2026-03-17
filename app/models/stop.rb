# frozen_string_literal: true

# Model class for a tour stop.
class Stop < ApplicationRecord
  include HtmlSanitizer

  has_many :tour_stops, dependent: :destroy
  has_many :tours, -> { distinct }, through: :tour_stops
  has_many :stop_media
  has_many :media, through: :stop_media
  belongs_to :medium, optional: true
  belongs_to :map_icon, optional: true
  has_many :stop_slugs, dependent: :delete_all
  validates :title, presence: true, uniqueness: { case_sensitive: false }

  before_validation -> { self.title ||= "untitled" }

  validates :title, presence: true

  after_initialize :default_values
  before_create :ensure_icon_color
  after_save :ensure_slug

  scope :by_slug_and_tour, lambda { |slug, tour_id| joins(:stop_slugs).joins(:tours).where("stop_slugs.slug = ?", slug).where("tour_stops.tour_id = ?", tour_id) }

  def sanitized_description
    HtmlSanitizer.accessible(description)
  end

  def sanitized_direction_notes
    HtmlSanitizer.accessible(direction_notes)
  end

  def slug
    title ? title.parameterize_intl : ""
  end

  def splash
    splash_medium = if medium.present?
      medium
    elsif stop_media.present?
      stop_media.order(:position).first.medium
    else
      nil
    end

    if splash_medium&.files
      return { title: splash_medium.title, caption: splash_medium.caption, url: splash_medium.search_data[:files][:desktop] }
    end
    nil
  end

  def orphaned
    tours.empty?
  end

  def published
    tours.any? { |tour| tour.published }
  end

  def should_index?
    !orphaned
  end

  def search_data
    {
      address:,
      article_link:,
      description:,
      direction_intro:,
      direction_notes:,
      icon_color:,
      id:,
      lat: lat&.to_f,
      lng: lng&.to_f,
      map_icon: map_icon&.original_image_url || nil,
      media: stop_media.sort_by(&:position).map(&:search_data),
      meta_description:,
      orphaned:,
      parking_lat: parking_lat&.to_f,
      parking_lng: parking_lng&.to_f,
      published:,
      sanitized_description:,
      slug:,
      slugs: stop_slugs.map(&:slug),
      splash:,
      title:,
      type: "stop",
      video_embed:,
      video_poster:
    }
  end

  private

    def default_values
      self.meta_description ||= HtmlSanitizer.accessible_truncated(self.description)
    end

    def ensure_slug
      stop_slug = title.parameterize_intl
      existing = StopSlug.find_by(slug: stop_slug)

      if existing
        existing.update(stop: self) unless existing.stop == self
      else
        stop_slugs.create(slug: stop_slug)
      end
    end

    def ensure_icon_color
      self.icon_color = "#D32F2F" if icon_color.nil?
    end
end
