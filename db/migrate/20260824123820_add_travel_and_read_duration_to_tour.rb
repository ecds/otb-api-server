# frozen_string_literal: true

class AddTravelAndReadDurationToTour < ActiveRecord::Migration[8.0]
  def change
    add_column(:tours, :travel_duration, :integer)
    add_column(:tours, :read_duration, :integer)
  end
end
