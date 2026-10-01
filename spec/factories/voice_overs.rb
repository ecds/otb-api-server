# frozen_string_literal: true

# spec/factories/media.rb
FactoryBot.define do
  factory :voice_over do
    association :tour
  end
end
