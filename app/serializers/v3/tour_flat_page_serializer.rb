module V3
  class TourFlatPageSerializer < ActiveModel::Serializer
    belongs_to :tour
    belongs_to :flat_page
    attributes :id, :position
  end
end
