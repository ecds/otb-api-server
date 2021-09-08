# frozen_string_literal: true

# spec/factories/tour_media.rb
FactoryBot.define do
  factory :tour_medium do
    association :tour
    association :medium
    position { 1 }
  end
end
