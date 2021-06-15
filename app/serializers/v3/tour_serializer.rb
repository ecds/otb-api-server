# frozen_string_literal: true

# app/serializers/tour_serializer.rb
class V3::TourSerializer < V3::TourBaseSerializer
  has_many :tour_modes
  has_many :tour_stops
  has_many :stops
  belongs_to :mode
  belongs_to :theme
  has_many :modes
  has_many :media
  has_many :tour_media
  has_many :flat_pages
  has_many :tour_flat_pages

  attributes :bounds
end
