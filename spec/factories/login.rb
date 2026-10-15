# frozen_string_literal: true

# spec/factories/login.rb
require 'faker'
require 'jwt'

FactoryBot.define do
  factory :login, class: 'EcdsRailsAuthEngine::Login' do
    provider { Faker::Internet.domain_name }
    user_id { nil }

    after(:create) do |login|
      create_list(:token, 1, login:)
    end
  end
end
