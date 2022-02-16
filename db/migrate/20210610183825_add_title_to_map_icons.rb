class AddTitleToMapIcons < ActiveRecord::Migration[6.0]
  def change
    add_column :map_icon, :title, :string
    add_reference :stops, :map_icons, null: true, foreign_key: true
  end
end
