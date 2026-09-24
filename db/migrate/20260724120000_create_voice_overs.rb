# frozen_string_literal: true

class CreateVoiceOvers < ActiveRecord::Migration[8.0]
  def change
    create_table(:voice_overs) do |t|
      t.references(:tour, foreign_key: true)
      t.references(:stop, foreign_key: true)
      t.string(:language, null: false, default: 'en')

      t.timestamps
    end
  end
end
