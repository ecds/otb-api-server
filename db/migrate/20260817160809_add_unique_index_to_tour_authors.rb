# frozen_string_literal: true

class AddUniqueIndexToTourAuthors < ActiveRecord::Migration[8.0]
  def up
    # Remove any pre-existing duplicate (tour_id, user_id) pairs before
    # adding the unique index below, keeping the earliest record for each
    # pair. Without this, the index creation would fail outright on any
    # tenant schema that already has duplicates.
    execute(<<~SQL.squish)
      DELETE FROM tour_authors
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM tour_authors
        GROUP BY tour_id, user_id
      )
    SQL

    add_index(:tour_authors, [:tour_id, :user_id], unique: true)
  end

  def down
    remove_index(:tour_authors, [:tour_id, :user_id])
  end
end
