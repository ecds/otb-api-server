class ChangeLatLngType < ActiveRecord::Migration[6.1]
  def change
    change_column :map_overlays, :south, :string
    change_column :map_overlays, :north, :string
    change_column :map_overlays, :east, :string
    change_column :map_overlays, :west, :string
    change_column :stops, :lat, :string
    change_column :stops, :lng, :string
    change_column :stops, :parking_lat, :string
    change_column :stops, :parking_lng, :string
  end
end
