class RemoveTourFromStopSlugs < ActiveRecord::Migration[8.0]
  def change
    remove_reference :stop_slugs, :tour, null: false, foreign_key: true
  end
end
