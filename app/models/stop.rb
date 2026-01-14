# frozen_string_literal: true

# Model class for a tour stop.
class Stop < ApplicationRecord
  include HtmlSanitizer
  include Searchable

  has_many :tour_stops, dependent: :destroy
  has_many :tours, -> { distinct }, through: :tour_stops
  has_many :stop_media
  has_many :media, through: :stop_media
  belongs_to :medium, optional: true
  belongs_to :map_icon, optional: true
  has_many :stop_slugs, dependent: :delete_all

  before_validation -> { self.title ||= 'untitled' }

  validates :title, presence: true

  after_initialize :default_values
  before_create :ensure_icon_color
  after_save :ensure_slug

  scope :by_slug_and_tour, lambda { |slug, tour_id| joins(:stop_slugs).joins(:tours).where('stop_slugs.slug = ?', slug).where('tour_stops.tour_id = ?', tour_id) }

  def sanitized_description
    HtmlSanitizer.accessible(description)
  end

  def sanitized_direction_notes
    HtmlSanitizer.accessible(direction_notes)
  end

  def slug
    title ? title.parameterize_intl : ''
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
      return { title: splash_medium.title, caption: splash_medium.caption, url: splash_medium.files[:desktop] }
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
      icon: map_icon&.original_image_url,
      icon_color:,
      lat:,
      lng:,
      map_icon: map_icon&.original_image_url || nil,
      media: media_index,
      meta_description:,
      parking_lat:,
      parking_lng:,
      sanitized_description:,
      slug:,
      splash:,
      title:,
      type: 'stop',
      video_embed:,
      video_poster:,
    }
  end

  private

    def default_values
      self.meta_description ||= HtmlSanitizer.accessible_truncated(self.description)
    end

    def ensure_slug
      tour_stops.each { |ts| ts.save }
    end

    def ensure_icon_color
      self.icon_color = '#D32F2F' if icon_color.nil?
    end

    def media_index
      indexed_media = stop_media.map do |m|
        medium_index(m, tours.first.tenant)
      end
      
      indexed_media.sort_by { |m| m[:position] }
    end

end
