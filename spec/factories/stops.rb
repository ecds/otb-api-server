# frozen_string_literal: true

# spec/factories/stops.rb
FactoryBot.define do
  factory :stop do
    sequence :title do |s|
      "#{Faker::Movies::HitchhikersGuideToTheGalaxy.planet}#{s}"
    end
    description { Faker::Hipster.paragraph(sentence_count: 2, supplemental: true, random_sentences_to_add: 4) }
    lat { Faker::Address.latitude }
    lng { Faker::Address.longitude }
    created_at { Faker::Number.number(digits: 10) }

    factory :stop_with_media do
      transient do
        media_count { 5 }
      end

      # https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md#transient-attributes
      after(:create) do |stop, evaluator|
        # create_list(:medium, evaluator.media_count, stops: [stop])
      end
    end
  end
end
