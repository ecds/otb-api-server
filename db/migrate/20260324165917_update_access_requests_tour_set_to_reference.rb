# frozen_string_literal: true

class UpdateAccessRequestsTourSetToReference < ActiveRecord::Migration[8.0]
  def change
    remove_column(:access_requests, :tour_set, :string)
    add_reference(:access_requests, :tour_set, foreign_key: true, null: false)
  end
end
