class AddDuration < ActiveRecord::Migration[6.1]
  def change
    add_column :tours, :duration, :integer
    add_column :tours, :saved_stop_order, :integer, array: true
  end
end
