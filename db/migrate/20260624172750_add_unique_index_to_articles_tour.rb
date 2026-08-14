# frozen_string_literal: true

class AddUniqueIndexToArticlesTour < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index(
      :tours,
      'LOWER(title)',
      name: 'index_articles_on_lower_title',
      unique: true,
      algorithm: :concurrently,
    )
  end
end
