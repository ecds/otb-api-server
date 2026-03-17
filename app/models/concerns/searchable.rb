# frozen_string_literal: true

# Common stuff for indexing
module Searchable
  extend ActiveSupport::Concern

  included do
    searchkick index_name: -> { "otb_#{Apartment::Tenant.current}_#{model_name.plural}_#{Rails.env}" },
    callbacks: false,
    deep_paging: true,
    merge_mappings: true, mappings: {
      properties: {
        slugs: { type: "keyword" }
      }
    },
    searchable: [ :slugs ], word: false

    after_commit :reindex_record
  end

  private

  def reindex_record
    ReindexJob.perform_later(tenant: Apartment::Tenant.current, class_name: self.class.name, id:)
  end
end
