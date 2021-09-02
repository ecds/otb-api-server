# frozen_string_literal: true

# spec/factories/media.rb
FactoryBot.define do
  factory :medium do
    title { Faker::TvShows::RickAndMorty.character }
    caption { Faker::TvShows::RickAndMorty.quote }
    filename { Faker::File.file_name(dir: '', ext: 'png', directory_separator: '') }
    base_sixty_four { File.read(Rails.root.join('spec/factories/base64_image.txt')) }
    created_at { Faker::Number.number(digits: 10) }
  end
end
