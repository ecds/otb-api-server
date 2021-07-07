class AddFileUrlsToMedia < ActiveRecord::Migration[6.0]
  def change
    add_column :media, :mobile, :string
    add_column :media, :tablet, :string
    add_column :media, :desktop, :string
  end
end
