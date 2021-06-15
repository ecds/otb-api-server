class AddParkingAddress < ActiveRecord::Migration[6.0]
  def change
    add_column :stops, :parking_address, :string
  end
end
