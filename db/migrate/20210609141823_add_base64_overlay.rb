class AddBase64Overlay < ActiveRecord::Migration[6.0]
  def change
    add_column :map_overlays, :base_sixty_four, :text
  end
end
