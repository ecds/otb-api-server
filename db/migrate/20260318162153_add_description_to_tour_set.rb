# frozen_string_literal: true

class AddDescriptionToTourSet < ActiveRecord::Migration[8.0]
  def change
    add_column(:tour_sets, :description, :text)
  end
end
