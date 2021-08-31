class ChangeBodyTypeForFlatPages < ActiveRecord::Migration[6.1]
  def change
    change_column :flat_pages, :body, :text
  end
end
