# frozen_string_literal: true

# app/serializer/user_serializer.rb
class V3::UserSerializer < ActiveModel::Serializer
  has_many :tours
  has_many :tour_sets
  attributes :id, :display_name, :super, :current_tenant_admin, :provider, :email

  def current_tenant_admin
    object.current_tenant_admin?
  end
end
