class AddTermAcceptedToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :terms_accepted, :boolean, default: false
  end
end
