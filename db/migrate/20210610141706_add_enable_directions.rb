class AddEnableDirections < ActiveRecord::Migration[6.0]
  def change
    add_column :tours, :use_directions, :boolean, default: true
  end
end
