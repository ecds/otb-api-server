# frozen_string_literal: true

class CreateAccessRequests < ActiveRecord::Migration[8.0]
  def change
    create_table(:access_requests) do |t|
      t.string(:tour_set, null: false)
      t.integer(:tour, null: true)
      t.belongs_to(:user, foreign_key: true)
      t.boolean(:approved, default: false)
      t.timestamps
    end
  end
end
