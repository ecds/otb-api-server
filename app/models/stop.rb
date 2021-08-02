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

  validates :title, presence: true
  # validates :title, uniqueness: true

  after_initialize :default_values
  after_save :ensure_slug

  before_validation -> { self.title ||= 'untitled' }

  # scope :not_in_tour, lambda { |tour_id| includes(:tour_stops).where.not(tour_stops: { tour_id: tour_id }) }
  # scope :no_tours, lambda { includes(:tour_stops).where(tour_stops: { tour_id: nil }) }
  # scope :published, lambda { includes(:tours).where(tours: { published: true }) }
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
end
