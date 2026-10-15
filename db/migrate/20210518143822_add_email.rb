# frozen_string_literal: true

class AddEmail < ActiveRecord::Migration[5.2]
  def change
    add_column(:users, :email, :string)
  end
end
