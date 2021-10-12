# frozen_string_literal: true

module V3
  class StopMediumSerializer < ActiveModel::Serializer
    belongs_to :stop
    belongs_to :medium
    attributes :id, :position
  end
end
