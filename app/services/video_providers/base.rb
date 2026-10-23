# frozen_string_literal: true

module VideoProviders
  # Generic embed: the embed_id is the URL itself, and the title and
  # thumbnail come from the page's Open Graph tags.
  class Base
    # Finds the provider's id for an item in its URLs. Generic embeds have
    # none: their embed_id is the URL itself.
    EMBED_ID = nil

    class << self
      # The provider's id for the item in a URL, or nil.
      def embed_id_from(url)
        self::EMBED_ID&.match(url.to_s)&.captures&.first
      end
    end

    # medium only needs an embed_id to build URLs; call also writes title,
    # caption, embed and filename onto it.
    def initialize(medium)
      @medium = medium
    end

    def embed_url
      v = @medium.embed_id
      v.start_with?('http', '//') ? v : "https://#{v}"
    end

    # A picture of the item, or nil. Nothing is downloaded.
    def thumbnail_url
      page.at_xpath('/html/head/meta[@property="og:image"]')&.[](:content)
    end

    # Fills in the medium and returns the thumbnail image's bytes.
    def call
      @medium.embed = embed_url
      @medium.title = page.at_xpath('/html/head/meta[@property="og:title"]')&.[](:content) ||
        page.at('title')&.text ||
        'A Model'
      image_url = thumbnail_url
      if image_url
        @medium.filename = File.basename(URI.parse(image_url).path)
        HTTParty.get(image_url).body
      else
        @medium.filename ||= 'otblogo.png'
        File.read(Rails.root.join('public/otblogo.png'))
      end
    end

    private

    def page
      @page ||= Nokogiri::HTML(HTTParty.get(absolute(embed_url)).body)
    end

    def absolute(url)
      url.start_with?('//') ? "https:#{url}" : url
    end
  end
end
