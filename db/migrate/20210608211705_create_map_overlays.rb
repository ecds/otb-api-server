class CreateMapOverlays < ActiveRecord::Migration[6.0]
  def change
    create_table :map_overlays do |t|
      t.decimal "south", precision: 100, scale: 8
      t.decimal "north", precision: 100, scale: 8
      t.decimal "east", precision: 100, scale: 8
      t.decimal "west", precision: 100, scale: 8
      t.references :tour, null: true
      t.references :stop, null: true

      t.timestamps
    end
  end
end
