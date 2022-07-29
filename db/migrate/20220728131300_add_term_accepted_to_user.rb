class AddTermAcceptedToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :terms_accepted, :boolean, default: false
  end
end
