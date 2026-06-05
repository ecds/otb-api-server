# frozen_string_literal: true

# spec/support/cookies.rb
class Rack::Test::CookieJar
  def encrypted = self
  def signed = self
  def permanent = self # I needed this, too
end
