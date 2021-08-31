class ChangePercisions < ActiveRecord::Migration[6.1]
  def change
    change_column :map_overlays, :south, :decimal, precision: 10, scale: 6
    change_column :map_overlays, :north, :decimal, precision: 10, scale: 6
    change_column :map_overlays, :east, :decimal, precision: 10, scale: 6
    change_column :map_overlays, :west, :decimal, precision: 10, scale: 6
    change_column :stops, :lat, :decimal, precision: 10, scale: 6
    change_column :stops, :lng, :decimal, precision: 10, scale: 6
    change_column :stops, :parking_lat, :decimal, precision: 10, scale: 6
    change_column :stops, :parking_lng, :decimal, precision: 10, scale: 6
    change_column :tour_tags, :lat, :decimal, precision: 10, scale: 6
    change_column :tour_tags, :lng, :decimal, precision: 10, scale: 6
  end
end
