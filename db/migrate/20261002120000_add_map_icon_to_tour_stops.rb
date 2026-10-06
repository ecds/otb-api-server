# frozen_string_literal: true

class AddMapIconToTourStops < ActiveRecord::Migration[8.0]
  def up
    add_reference(:tour_stops, :map_icon, foreign_key: false, index: true)

    # Carry each stop's current icon onto every tour it appears in.
    execute(<<~SQL.squish)
      UPDATE tour_stops
      SET map_icon_id = stops.map_icon_id
      FROM stops
      WHERE tour_stops.stop_id = stops.id AND stops.map_icon_id IS NOT NULL
    SQL
  end

  def down
    remove_reference(:tour_stops, :map_icon, index: true)
  end
end
