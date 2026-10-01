# frozen_string_literal: true

class AddEmbedIdToMedium < ActiveRecord::Migration[8.0]
  def change
    add_column(:media, :embed_id, :string)
    # rubocop:disable Rails/ReversibleMigration
    # The reverse is just to delete the column
    execute(<<-SQL)
      UPDATE media#{" "}
      SET embed_id = video
    SQL
    # rubocop:enable Rails/ReversibleMigration
  end
end
