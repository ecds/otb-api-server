class MapIcon < MediumBaseRecord
  validate :check_dimensions

  has_one :stop

  def published
    stop.published
  end

  def check_dimensions
    return if base_sixty_four.nil?

    file = MiniMagick::Image.read(Base64.decode64(base_sixty_four))

    if file[:height] > 80 || file[:width] > 80
      errors.add(:base, 'Icons should be no bigger that 80 by 80 pixels')
    end
  end
end
