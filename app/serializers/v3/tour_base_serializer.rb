# frozen_string_literal: true

# app/serializers/tour_serializer.rb
class V3::TourBaseSerializer < ActiveModel::Serializer
  has_one :map_overlay
  attributes :id, :title, :slug, :description, :is_geo, :published, :sanitized_description, :position, :theme_title, :meta_description, :splash, :tenant, :tenant_title, :stop_count, :map_type, :splash_width, :splash_height, :insecure_splash, :use_directions, :default_lng
end
