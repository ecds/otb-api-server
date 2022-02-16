# frozen_string_literal: true

include ActionView::Helpers::DateHelper

# app/serializers/tour_serializer.rb
module V3
  class TourBaseSerializer < ActiveModel::Serializer
    has_one :map_overlay
    attributes :id,
              :title,
              :slug,
              :description,
              :is_geo,
              :published,
              :sanitized_description,
              :position,
              :theme_title,
              :meta_description,
              :tenant,
              :tenant_title,
              :stop_count,
              :map_type,
              :splash,
              :use_directions,
              :default_lng,
              :stop_count,
              :est_time,
              :link_address,
              :link_text,
              :restrict_bounds,
              :restrict_bounds_to_overlay,
              :blank_map

    def est_time
      return nil if object.duration.nil?

      "#{distance_of_time_in_words(object.duration).capitalize} #{object.mode.title.downcase}"
    end

    def map_type
      object.map_type || 'hybrid'
    end

    def bounds
      return object.bounds if object.bounds.present?

      if @instance_options[:loc].present?
        return @instance_options[:loc]
      end

      nil
    end
  end
end
