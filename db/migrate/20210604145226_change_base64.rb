class ChangeBase64 < ActiveRecord::Migration[6.0]
  def change
    rename_column :media, :base64, :base_sixty_four
  end
end
