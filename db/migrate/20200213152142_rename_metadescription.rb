class RenameMetadescription < ActiveRecord::Migration[5.2]
  def change
    begin
      rename_column :stops, :metadescription, :meta_description
    rescue
      # It's fine
    end
  end
end
