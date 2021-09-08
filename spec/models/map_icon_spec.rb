require 'rails_helper'

RSpec.describe MapIcon, type: :model do
  context 'size error' do
    it 'fails validation when image it too big' do
      icon = MapIcon.create(
        base_sixty_four: File.read(Rails.root.join('spec/factories/images/png_base64.txt')),
        filename: Faker::File.file_name(dir: '', ext: 'png', directory_separator: '')
      )
      expect(icon.errors.full_messages).to include 'Icons should be no bigger that 80 by 80 pixels'
    end
  end
end
