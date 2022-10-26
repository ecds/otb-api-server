# frozen_string_literal: true

class FlatPage < ApplicationRecord
  has_many :tour_flat_pages
  has_many :tours, through: :tour_flat_pages
  validates :title, presence: true

  def slug
    title ? title.parameterize_intl : ''
  end

  def orphaned
    tours.empty?
  end

  def published
    tours.any? { |tour| tour.published }
  end
end
