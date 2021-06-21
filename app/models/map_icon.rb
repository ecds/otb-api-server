class MapIcon < MediumBaseRecord
  validate :check_dimensions

  def check_dimensions
    return if base_sixty_four.nil?

    headers, tmp_base_sixty_four = base_sixty_four.split(',')
    file = MiniMagick::Image.read(Base64.decode64(tmp_base_sixty_four))

    if file[:height] > 80 || file[:width] > 80
      errors.add(:base, 'Icons should be no bigger that 80 by 80 pixels')
    end
  end
end
