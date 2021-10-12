# frozen_string_literal: true

# /app/serializers/tour_stop_serializer.rb
module V3
  class TourStopSerializer < ActiveModel::Serializer
    belongs_to :tour
    belongs_to :stop
    attributes :id, :position, :previous, :slug, :next, :next_slug, :previous_slug
  end
end
