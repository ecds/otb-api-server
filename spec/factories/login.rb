# frozen_string_literal: true

# spec/factories/login.rb
require 'faker'
require 'jwt'

FactoryBot.define do
  factory :login, class: EcdsRailsAuthEngine::Login do
    token { JWT.encode(Faker::Beer.style, Faker::Address.zip, 'HS256') }
  end
end
