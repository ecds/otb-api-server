# frozen_string_literal: true

class V3::TourModeSerializer < ActiveModel::Serializer
  belongs_to :tour
  belongs_to :mode
  attributes :id
end
