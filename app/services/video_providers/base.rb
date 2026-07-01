# frozen_string_literal: true

module VideoProviders
  class Base
    def initialize(medium)
      @medium = medium
    end

    def embed_url
      v = @medium.embed_id
      v.start_with?('http', '//') ? v : "https://#{v}"
    end

    def call
      @medium.embed = embed_url
      fetch_url = @medium.embed.start_with?('//') ? "https:#{@medium.embed}" : @medium.embed
      doc = Nokogiri::HTML(HTTParty.get(fetch_url).body)
      @medium.title = doc.at_xpath('/html/head/meta[@property="og:title"]')&.[](:content) ||
        doc.at('title')&.text ||
        'A Model'
      image_url = doc.at_xpath('/html/head/meta[@property="og:image"]')&.[](:content)
      if image_url
        @medium.filename = File.basename(URI.parse(image_url).path)
        HTTParty.get(image_url).body
      else
        @medium.filename ||= 'otblogo.png'
        File.read(Rails.root.join('public/otblogo.png'))
      end
    end
  end
end
