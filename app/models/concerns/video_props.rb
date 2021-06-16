# frozen_string_literal: true

require 'open-uri'

module VideoProps
  extend ActiveSupport::Concern

  def self.props(medium)
    return if medium.video.nil?
    case medium.video_provider
    when 'keiner'
      nil
    when 'vimeo'
      metadata = HTTParty.get("https://vimeo.com/api/oembed.json?url=https%3A//vimeo.com/video/#{medium.video}")
      medium.title = metadata['title']
      medium.caption = metadata['description']
      medium.embed = "//player.vimeo.com/video/#{medium.video}"
      downloaded_image = open(metadata['thumbnail_url'])
      medium.public_send("#{Apartment::Tenant.current.underscore}_file").attach(io: downloaded_image, filename: "#{medium.video}.jpg")
    when 'youtube'
      begin
        metadata = Yt::Video.new(id: medium.video)
        medium.title = metadata.title
        medium.caption = metadata.description
        medium.embed = "//www.youtube.com/embed/#{medium.video}"
        downloaded_image = open("https://img.youtube.com/vi/#{medium.video}/0.jpg")
        medium.public_send("#{Apartment::Tenant.current.underscore}_file").attach(io: downloaded_image, filename: "#{medium.video}.jpg")
      rescue Yt::Errors::NoItems
        medium.provider = nil
        medium.video = nil
      end
    when 'soundcloud'
      if medium.video.include?('iframe')
        embed_code = Nokogiri::HTML(medium.video)
        titles = embed_code.xpath('//a').map { |a| a[:title] }
        if titles.length > 1
          medium.title = titles.join(': ')
        else
          medium.title = titles.first
        end
        medium.video = embed_code.xpath('//iframe', 'src').first['src'].split('&').first[/(.*tracks\/)(.*)/, 2]
        medium.embed = "//w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/#{medium.video}&color=%23ff5500&auto_play=false&hide_related=true&show_comments=false&show_user=false&show_reposts=false&show_teaser=false&visual=true&sharing=false"
        browser = Ferrum::Browser.new()
        browser.go_to("https:#{medium.embed}")
        spans = browser.at_xpath('//span[contains(@class, "sc-artwork")]') until spans.present?
        image = spans.attribute('style')[/(.*\()(.*)(\).*)/, 2]
        if image.nil?
          medium.public_send("#{Apartment::Tenant.current.underscore}_file").attach(
            io: File.open(File.join(Rails.root, 'public', 'soundcloud.jpg')),
            filename: "#{medium.title.parameterize}.jpg"
          )
        else
          downloaded_image = open("https:#{image}")
          medium.public_send("#{Apartment::Tenant.current.underscore}_file").attach(io: downloaded_image, filename: "#{medium.title.parameterize}.jpg")
        end
      end

    end
  end
end
