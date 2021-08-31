class DropTagTables < ActiveRecord::Migration[6.1]
  def change
    drop_table :tour_tags
    drop_table :stop_tags
    drop_table :tags
  end
end
