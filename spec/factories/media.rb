# frozen_string_literal: true

# spec/factories/media.rb
FactoryBot.define do
  factory :medium do
    title { Faker::TvShows::RickAndMorty.character }
    caption { Faker::TvShows::RickAndMorty.quote }
    # file { Rack::Test::UploadedFile.new(Rails.root.join("spec", "factories", "images", "0.jpg"), "image/jpeg") }
    filename { Faker::File.file_name(dir: '', ext: 'jpg', directory_separator: '') }
    base_sixty_four { File.read(Rails.root.join('spec/factories/base64_image.txt')) }
    video_provider { 'keiner' }
    video { nil }
  end
end
