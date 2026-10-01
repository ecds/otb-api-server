# frozen_string_literal: true

class FixSlugId < ActiveRecord::Migration[6.1]
  def change
    remove_column(:slugs, :id)
    add_column(:slugs, :id, :primary_key)
  end
end
