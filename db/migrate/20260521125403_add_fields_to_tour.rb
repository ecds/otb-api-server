# frozen_string_literal: true

class AddFieldsToTour < ActiveRecord::Migration[8.0]
  def change
    add_column(:tours, :open_geographies, :boolean)
    add_column(:tours, :open_geographies_endpoint, :string)
  end
end
