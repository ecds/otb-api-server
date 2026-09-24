# frozen_string_literal: true

class AddMapIconIdToTours < ActiveRecord::Migration[8.0]
  def change
    add_reference(:tours, :map_icon, foreign_key: true, index: true)
  end
end
