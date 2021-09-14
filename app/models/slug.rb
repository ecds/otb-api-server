# frozen_string_literal: true

class Slug < ApplicationRecord
  belongs_to :tour
  validates :slug, uniqueness: true

  # attr_accessor :published

  # def published
  #   tour.published
  # end
end
