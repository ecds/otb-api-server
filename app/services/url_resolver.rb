# frozen_string_literal: true

module UrlResolver
  def self.resolve(url)
    loop do
      response = HTTParty.head(url, follow_redirects: false)
      break url unless response.redirection?
      url = response.headers['location']
    end
  end
end
