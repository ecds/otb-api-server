class V3::TourAuthorSerializer < ActiveModel::Serializer
  belongs_to :tour
  belongs_to :user
  attributes :id
end
