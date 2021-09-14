# frozen_string_literal: true

# spec/factories/tour_authors.rb
FactoryBot.define do
  factory :tour_author do
    association :tour
    association :user
  end
end
