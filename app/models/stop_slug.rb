# frozen_string_literal: true

class StopSlug < ApplicationRecord
  belongs_to :stop
  validates :slug, uniqueness: true
end
