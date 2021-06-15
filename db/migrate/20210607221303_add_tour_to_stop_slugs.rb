class AddTourToStopSlugs < ActiveRecord::Migration[6.0]
  def change
    add_reference :stop_slugs, :tour, foreign_key: true
  end
end
