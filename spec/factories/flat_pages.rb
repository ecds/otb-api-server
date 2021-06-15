# frozen_string_literal: true

# spec/factories/users.rb
FactoryBot.define do
  factory :flat_page do
    title { Faker::Movies::HitchhikersGuideToTheGalaxy.planet }
    body { Faker::Hipster.paragraph(sentence_count: 2, supplemental: true, random_sentences_to_add: 4) }
  end
end
