class ChangeTitleToFilename < ActiveRecord::Migration[6.0]
  def change
    rename_column :map_icons, :title, :filename
    rename_column :map_overlays, :title, :filename
  end
end
