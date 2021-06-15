class CreateMapIcons < ActiveRecord::Migration[6.0]
  def change
    create_table :map_icons do |t|
      t.text :base_sixty_four

      t.timestamps
    end
  end
end
