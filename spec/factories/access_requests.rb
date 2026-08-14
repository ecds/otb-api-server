# frozen_string_literal: true

# spec/factories/users.rb
FactoryBot.define do
  factory :access_request do
    user { create(:user) }
  end
end
