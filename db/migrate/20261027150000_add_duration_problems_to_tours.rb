# frozen_string_literal: true

class AddDurationProblemsToTours < ActiveRecord::Migration[8.0]
  def change
    # Why parts of the tour's travel time couldn't be worked out, for the admin.
    add_column(:tours, :duration_problems, :jsonb, default: [], null: false)
  end
end
