class ChangeIdTypes < ActiveRecord::Migration[6.1]
  def change
    change_column :tours, :mode_id, :bigint
    change_column :tours, :splash_image_medium_id, :bigint
  end
end
