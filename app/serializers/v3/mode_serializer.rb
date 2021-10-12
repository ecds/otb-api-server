# frozen_string_literal: true

module V3
  class ModeSerializer < ActiveModel::Serializer
    has_many :tours
    attributes :id, :title, :icon
  end
end
