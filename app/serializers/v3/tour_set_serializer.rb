# frozen_string_literal: true

class V3::TourSetSerializer < ActiveModel::Serializer
  # attribute :tenant_admins
  include Rails.application.routes.url_helpers
  has_many :admins
  attributes :id, :name, :subdir, :published_tours, :mapable_tours, :logo_url, :logo

  def admins
    object.admins if current_user.super || current_user.current_tenant_admin?
  end
end
