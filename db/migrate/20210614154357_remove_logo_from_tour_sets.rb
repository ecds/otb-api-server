class RemoveLogoFromTourSets < ActiveRecord::Migration[6.0]
  def change
    remove_column :tour_sets, :logo
  end
end
