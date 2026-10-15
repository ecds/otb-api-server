# frozen_string_literal: true

class AddTourIdsToAccessRequest < ActiveRecord::Migration[8.0]
  def change
    add_column(:access_requests, :tour_ids, :integer, array: true, default: [])
  end
end
