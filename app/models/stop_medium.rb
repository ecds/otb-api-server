# frozen_string_literal: true

# Model class for many to many association between stops and media
class StopMedium < ApplicationRecord
  belongs_to :medium
  belongs_to :stop

  def published
    stop&.published
  end

  after_create do
    self.position = self.position.nil? ? self.stop.media.length : self.position
    self.save
  end

  def search_data
    {
      relation_id: id,
      position:,
      **medium&.search_data
    }
  end
end
