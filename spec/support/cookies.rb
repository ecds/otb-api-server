# frozen_string_literal: true

# spec/support/cookies.rb
module Rack
  module Test
    class CookieJar
      def encrypted = self
      def signed = self
      def permanent = self # I needed this, too
    end
  end
end
