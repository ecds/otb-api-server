# frozen_string_literal: true

# spec/factories/themes.rb
FactoryBot.define do
  factory :theme do
    title { Faker::Color.name }
  end
end
