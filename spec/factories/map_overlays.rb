# frozen_string_literal: true

# spec/factories/map_icons.rb
FactoryBot.define do
  factory :map_overlay do
    south { nil }
    east { nil }
    north { nil }
    west { nil }
    filename { Faker::File.file_name(dir: '', ext: 'png', directory_separator: '') }
    base_sixty_four { File.read(Rails.root.join('spec/factories/base64_image.txt')) }
    association :tour
  end
end
