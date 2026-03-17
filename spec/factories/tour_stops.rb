# frozen_string_literal: true

# spec/factories/tour_stops.rb
FactoryBot.define do
  factory :tour_stop do
    association :tour
    association :stop
  end
end
