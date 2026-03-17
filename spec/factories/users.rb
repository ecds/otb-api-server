# frozen_string_literal: true

# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    display_name { Faker::Music::Hiphop.artist }
    terms_accepted { false }
  end
end
