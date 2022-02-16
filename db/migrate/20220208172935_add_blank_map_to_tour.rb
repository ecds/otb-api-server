class AddBlankMapToTour < ActiveRecord::Migration[6.1]
  def change
    add_column :tours, :blank_map, :boolean, default: false
  end
end
