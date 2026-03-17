class AddColumnRotationToMapOverlay < ActiveRecord::Migration[8.0]
  def change
    add_column :map_overlays, :rotation, :integer, default: 0
  end
end
