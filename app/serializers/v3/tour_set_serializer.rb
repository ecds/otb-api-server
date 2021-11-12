# frozen_string_literal: true

module V3
  class TourSetSerializer < ActiveModel::Serializer
    # attribute :tenant_admins
    include Rails.application.routes.url_helpers
    has_many :admins
    attributes :id, :name, :subdir, :published_tours, :mapable_tours, :logo_url, :logo

    def admins
      begin
        object.admins if current_user&.super || current_user&.tour_sets.include?(object)
      rescue NameError
        # This is a problem when using the serializer directly
        nil
      end
    end
  end
end
