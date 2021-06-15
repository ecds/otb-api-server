class AddTitleOverlay < ActiveRecord::Migration[6.0]
  def change
    add_column :map_overlays, :title, :text
  end
end
