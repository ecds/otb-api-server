# frozen_string_literal: true

# spec/factories/login.rb
require 'faker'
require 'jwt'

FactoryBot.define do
  factory :login, class: EcdsRailsAuthEngine::Login do
    provider { Faker::Internet.domain_name }
    user_id { nil }
  end
end
