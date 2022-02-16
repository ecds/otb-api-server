class AddRestrictBoundsToTour < ActiveRecord::Migration[6.1]
  def change
    add_column :tours, :restrict_bounds, :boolean, default: true
  end
end
