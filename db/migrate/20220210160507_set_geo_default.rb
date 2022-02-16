class SetGeoDefault < ActiveRecord::Migration[6.1]
  def change
    change_column :tours, :is_geo, :boolean, default: true
  end
end
