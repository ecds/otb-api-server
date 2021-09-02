class AddWidthsToMedium < ActiveRecord::Migration[6.1]
  def change
    add_column :media, :lqip_width, :integer
  end
end
