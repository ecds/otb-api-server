# frozen_string_literal: true

module V3
  class ThemeSerializer < ActiveModel::Serializer
    attributes :id, :title
  end
end
