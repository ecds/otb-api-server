# frozen_string_literal: true

class RenameMetadescription < ActiveRecord::Migration[5.2]
  def change
    rename_column(:stops, :metadescription, :meta_description)
  rescue StandardError
    # It's fine
  end
end
