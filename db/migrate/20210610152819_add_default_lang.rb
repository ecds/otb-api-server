class AddDefaultLang < ActiveRecord::Migration[6.0]
  def change
    add_column :tours, :default_lng, :integer, default: 0
  end
end
