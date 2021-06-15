class AddLogoTitleToTourSets < ActiveRecord::Migration[6.0]
  def change
    add_column :tour_sets, :logo_title, :string
  end
end
