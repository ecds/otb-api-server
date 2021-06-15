class AddBase64 < ActiveRecord::Migration[6.0]
  def change
    add_column :media, :base64, :text
  end
end
