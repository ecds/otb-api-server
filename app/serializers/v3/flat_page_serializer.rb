module V3
    class FlatPageSerializer < ActiveModel::Serializer
    has_many :tours
    attributes :id, :title, :body, :slug, :orphaned
  end
end
