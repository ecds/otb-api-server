class AddLinkToTour < ActiveRecord::Migration[6.1]
  def change
    add_column :tours, :link_address, :string
    add_column :tours, :link_text, :string
  end
end
