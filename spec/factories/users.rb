# frozen_string_literal: true

# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    display_name { Faker::Music::Hiphop.artist }
    terms_accepted { false }

    after(:create) do |user|
      create(:login, user_id: user.id) if user.login.blank?
    end
  end
end
