module V3
  class TourAuthorSerializer < ActiveModel::Serializer
    belongs_to :tour
    belongs_to :user
    attributes :id
  end
end
