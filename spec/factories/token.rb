# frozen_string_literal: true

# spec/factories/login.rb
require 'faker'
require 'jwt'

FactoryBot.define do
  factory :token, class: EcdsRailsAuthEngine::Token do
    token { JWT.encode(Faker::Beer.style, Faker::Address.zip, 'HS256') }
  end
end
