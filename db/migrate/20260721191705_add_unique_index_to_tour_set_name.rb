# frozen_string_literal: true

class AddUniqueIndexToTourSetName < ActiveRecord::Migration[8.0]
  def change
    add_index(:tour_sets, :name, unique: true)
  end
end
