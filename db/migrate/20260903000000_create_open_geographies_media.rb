# frozen_string_literal: true

class CreateOpenGeographiesMedia < ActiveRecord::Migration[8.0]
  def change
    create_table(:open_geographies_media) do |t|
      t.string(:uuid, null: false, index: { unique: true })
      t.string(:provider)
      t.string(:embed_url)
      t.string(:thumbnail_url)
      t.timestamps
    end
  end
end
