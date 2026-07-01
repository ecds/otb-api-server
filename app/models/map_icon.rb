# frozen_string_literal: true

class MapIcon < MediumBaseRecord
  validate :check_dimensions
  validates :file, dimension: { width: 80, height: 80, message: 'Icons should be no bigger that 80 by 80 pixels' }

  has_one :stop, dependent: :nullify
  has_one :tour, dependent: :nullify

  def published
    (stop || tour)&.published || false
  end

  def search_data
    { id: }
  end

  def check_dimensions
    return if base_sixty_four.nil?

    file_to_check = MiniMagick::Image.read(Base64.decode64(base_sixty_four))

    return if file_to_check[:height] <= 80 && file_to_check[:width] <= 80

    errors.add(:base, 'Icons should be no bigger that 80 by 80 pixels')
  end
end
