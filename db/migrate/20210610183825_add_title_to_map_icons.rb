class AddTitleToMapIcons < ActiveRecord::Migration[6.0]
  def change
    add_column :map_icons, :title, :string
    add_reference :stops, :map_icon, null: true, foreign_key: true
  end
end
