class CreateTourAuthors < ActiveRecord::Migration[6.0]
  def change
    create_table :tour_authors do |t|

      t.timestamps
    end
  end
end
