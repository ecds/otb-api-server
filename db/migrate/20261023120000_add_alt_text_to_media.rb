# frozen_string_literal: true

class AddAltTextToMedia < ActiveRecord::Migration[8.0]
  def change
    add_column(:media, :alt_text, :text)
    # Marked by a curator as adding nothing a screen reader user needs, so it
    # is published with an empty alt.
    add_column(:media, :decorative, :boolean, default: false, null: false)
  end
end
