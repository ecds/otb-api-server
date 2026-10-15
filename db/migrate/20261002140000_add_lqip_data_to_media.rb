# frozen_string_literal: true

class AddLqipDataToMedia < ActiveRecord::Migration[8.0]
  def change
    add_column(:media, :lqip_data, :text)
  end
end
