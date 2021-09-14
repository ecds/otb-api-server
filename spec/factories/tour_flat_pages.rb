# frozen_string_literal: true

# spec/factories/tour_flat_pages.rb
FactoryBot.define do
  factory :tour_flat_page do
    association :tour
    association :flat_page
  end
end
