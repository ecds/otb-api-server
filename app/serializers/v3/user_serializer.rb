# frozen_string_literal: true

# app/serializer/v3/user_serializer.rb
module V3
  class UserSerializer < ActiveModel::Serializer
    has_many :tours
    has_many :tour_authors
    has_many :tour_sets
    attributes :id, :display_name, :super, :current_tenant_admin, :provider, :email, :all_tours

    def current_tenant_admin
      object.current_tenant_admin?
    end

    def all_tours
      if @instance_options[:include_tours]
        return object.all_tours
      end
      []
    end
  end
end
