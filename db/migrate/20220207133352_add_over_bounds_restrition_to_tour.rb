class AddOverBoundsRestritionToTour < ActiveRecord::Migration[6.1]
  def change
    add_column :tours, :restrict_bounds_to_overlay, :boolean, default: false
  end
end
