# frozen_string_literal: true

class AddIconColorToTours < ActiveRecord::Migration[8.0]
  def change
    add_column(:tours, :icon_color, :string, default: '#D32F2F')
  end
end
