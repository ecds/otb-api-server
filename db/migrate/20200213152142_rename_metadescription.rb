class RenameMetadescription < ActiveRecord::Migration[5.2]
  def change
    rename_column :stops, :metadescription, :meta_description
  end
end
