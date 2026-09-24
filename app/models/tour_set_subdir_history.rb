# frozen_string_literal: true

# Records every subdir (tenant schema name) a TourSet has ever had, so
# requests using an old, since-renamed subdir can be redirected to the
# current one. See DirectoryElevator.
class TourSetSubdirHistory < ApplicationRecord
  belongs_to :tour_set

  validates :subdir, presence: true, uniqueness: true
end
