# frozen_string_literal: true

class AddIconColorToTourStops < ActiveRecord::Migration[8.0]
  def change
    add_column(:tour_stops, :icon_color, :string)
  end
end
