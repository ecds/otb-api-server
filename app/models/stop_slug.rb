class StopSlug < ApplicationRecord
  belongs_to :stop
  belongs_to :tour
  # validates :slug, uniqueness: true
end
