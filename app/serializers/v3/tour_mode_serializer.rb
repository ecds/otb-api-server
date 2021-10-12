# frozen_string_literal: true

module V3
  class TourModeSerializer < ActiveModel::Serializer
    belongs_to :tour
    belongs_to :mode
    attributes :id
  end
end
