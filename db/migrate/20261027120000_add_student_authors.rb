# frozen_string_literal: true

class AddStudentAuthors < ActiveRecord::Migration[8.0]
  def change
    add_column(:tour_authors, :student, :boolean, default: false, null: false)

    # Who added a stop or medium, so student authors can remove what they
    # added. Users live in the shared schema, so there's no foreign key.
    add_column(:stops, :created_by_id, :bigint)
    add_index(:stops, :created_by_id)
    add_column(:media, :created_by_id, :bigint)
    add_index(:media, :created_by_id)
  end
end
