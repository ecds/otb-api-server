# spec/support/cookies.rb
class Rack::Test::CookieJar
  def encrypted; self; end
  def signed; self; end
  def permanent; self; end # I needed this, too
end