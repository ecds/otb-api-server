# frozen_string_literal: true

class CreateTourSetSubdirHistories < ActiveRecord::Migration[8.0]
  def change
    create_table(:tour_set_subdir_histories) do |t|
      t.references(:tour_set, null: false, foreign_key: true)
      t.string(:subdir, null: false)

      t.timestamps
    end
    add_index(:tour_set_subdir_histories, :subdir, unique: true)
    add_index(:tour_sets, :subdir, unique: true)
  end
end
