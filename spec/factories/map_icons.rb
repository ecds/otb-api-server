# frozen_string_literal: true

# spec/factories/map_icons.rb
FactoryBot.define do
  factory :map_icon do
    filename { Faker::File.file_name(dir: '', ext: 'png', directory_separator: '') }
    base_sixty_four { File.read(Rails.root.join('spec/factories/images/icon_base64.txt')) }
    created_at { Faker::Number.number(digits: 10) }
  end
end
