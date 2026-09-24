class AddPublishedOnToTour < ActiveRecord::Migration[8.0]
  def change
    add_column :tours, :published_on, :date
  end
end
