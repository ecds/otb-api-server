# frozen_string_literal: true

module V3
  class TourMediumSerializer < ActiveModel::Serializer
    belongs_to :tour
    belongs_to :medium
    attributes :id, :position
  end
end
