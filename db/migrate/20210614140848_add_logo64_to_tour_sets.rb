class AddLogo64ToTourSets < ActiveRecord::Migration[6.0]
  def change
    add_column :tour_sets, :base_sixty_four, :text
  end
end
