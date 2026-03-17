# frozen_string_literal: true

#
# Helper for making authenticated requests for controller specs.
#
module SignedCookieHelper
  def signed_cookie(user)
    login = EcdsRailsAuthEngine::Login.create!(who: user.email)
    login.user_id = user.id
    login.save!
    create(:token, login: login, token: TokenService.create(login))
    cookies.signed[:auth] = {
      value: login.tokens.first.token,
      httponly: true,
      same_site: :none,
      secure: 'Secure'
    }
  end

  # Used for mocking requests with bad credentials.
  def invalid_signed_cooke
    cookies.signed[:auth] = {
      value: JWT.encode(Faker::Beer.style, Faker::Address.zip, 'HS256'),
      httponly: true,
      same_site: :none,
      secure: 'Secure'
    }
  end
end
