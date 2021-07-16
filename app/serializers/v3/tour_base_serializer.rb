# frozen_string_literal: true

include ActionView::Helpers::DateHelper

# app/serializers/tour_serializer.rb
class V3::TourBaseSerializer < ActiveModel::Serializer
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
             :insecure_splash,
             :use_directions,
             :default_lng,
             :stop_count,
             :est_time

  def est_time
    return nil if object.duration.nil?

    distance_of_time_in_words(object.duration)
  end
end
