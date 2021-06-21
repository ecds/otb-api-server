class V3::FlatPageSerializer < ActiveModel::Serializer
  has_many :tours
  attributes :id, :title, :body, :slug, :orphaned
end
