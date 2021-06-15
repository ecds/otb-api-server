# frozen_string_literal: true

class V3::TourSetSerializer < ActiveModel::Serializer
  # attribute :tenant_admins
  include Rails.application.routes.url_helpers
  has_many :admins
  attributes :id, :name, :subdir, :published_tours, :logo_url

  def admins
    object.admins if current_user.super || current_user.current_tenant_admin?
  end

  def logo_url
    return nil unless object.logo.attached?
    rails_blob_url(object.logo)
  end
end
