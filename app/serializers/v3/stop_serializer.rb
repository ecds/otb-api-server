# frozen_string_literal: true

class V3::StopSerializer < ActiveModel::Serializer
  has_many :media
  has_many :stop_media
  has_many :tours
  belongs_to :map_icon
  attributes :id, :title, :slug, :description, :sanitized_description, :sanitized_direction_notes, :lat, :lng, :address, :meta_description, :article_link, :video_embed, :video_poster, :parking_lat, :parking_lng, :direction_intro, :direction_notes, :splash_url, :insecure_splash, :splash_width, :splash_height, :orphaned, :icon_color
end
