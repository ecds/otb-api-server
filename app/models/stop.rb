# frozen_string_literal: true

# Model class for a tour stop.
class Stop < ApplicationRecord
  include HtmlSaintizer

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
    HtmlSaintizer.accessable(description)
  end

  def sanitized_direction_notes
    HtmlSaintizer.accessable(direction_notes)
  end

  def slug
    title ? title.parameterize : ''
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

  def splash_height
    splash.nil? ? nil : 700 #splash.desktop_height
  end

  def splash_width
    splash.nil? ? nil : 700 #splash.desktop_width
  end

  def insecure_splash
    # if !stop_media.empty?
    #   return medium.nil? ? stop_media.order(:position).first.medium.insecure : medium.insecure
    # end
    nil
  end

  def is_published
    tours.published.present?
  end

  def orphaned
    tours.empty?
  end

  def published
    tours.any? { |tour| tour.published }
  end

  private

    def default_values
      self.meta_description ||= HtmlSaintizer.accessable_truncated(self.description)
    end

    def ensure_slug
      tour_stops.each { |ts| ts.save }
    end

    def ensure_icon_color
      self.icon_color = '#D32F2F' if icon_color.nil?
    end
end
