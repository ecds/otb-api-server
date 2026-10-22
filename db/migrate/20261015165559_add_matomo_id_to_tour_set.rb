# frozen_string_literal: true

class AddMatomoIdToTourSet < ActiveRecord::Migration[8.0]
  def change
    add_column(:tour_sets, :matomo_id, :integer, default: 4, null: false)
  end
end
