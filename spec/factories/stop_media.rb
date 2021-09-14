# frozen_string_literal: true

# spec/factories/stop_media.rb
FactoryBot.define do
  factory :stop_medium do
    association :stop
    association :medium
    position { 1 }
  end
end
