class V3::FlatPageSerializer < ActiveModel::Serializer
  attributes :id, :title, :body, :slug, :orphaned
end
