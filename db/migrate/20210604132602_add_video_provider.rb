class AddVideoProvider < ActiveRecord::Migration[6.0]
  def change
    add_column :media, :video_provider, :integer, default: 0
  end
end
