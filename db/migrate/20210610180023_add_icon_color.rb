class AddIconColor < ActiveRecord::Migration[6.0]
  def change
    add_column :stops, :icon_color, :string, default: '#D32F2F'
  end
end
