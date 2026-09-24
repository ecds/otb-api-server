# frozen_string_literal: true

class TourAuthor < ApplicationRecord
  belongs_to :tour
  belongs_to :user

  validates :user_id, uniqueness: { scope: :tour_id }
end
