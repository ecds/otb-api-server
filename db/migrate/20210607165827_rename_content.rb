class RenameContent < ActiveRecord::Migration[6.0]
  def change
    rename_column :flat_pages, :content, :body
  end
end
