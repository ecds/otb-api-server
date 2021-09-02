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
      thumbnail_width = metadata['thumbnail_width']
      thumbnail_height = metadata['thumbnail_height']
      scale_by = 1000 / thumbnail_width
      thumbnail_url = "#{metadata['thumbnail_url'].split('_')[0]}_#{thumbnail_width * scale_by}x#{thumbnail_height * scale_by}"
      downloaded_image = URI.open(thumbnail_url)
    when 'youtube'
      begin
        metadata = Yt::Video.new(id: medium.video)
        medium.title = metadata.title
        medium.caption = metadata.description
        medium.embed = "//www.youtube.com/embed/#{medium.video}"
        downloaded_image = URI.open("https://img.youtube.com/vi/#{medium.video}/0.jpg")
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
          downloaded_image = File.open(File.join(Rails.root, 'public', 'soundcloud.jpg')).read
        else
          downloaded_image = URI.open("https:#{image}")
        end
      end

    end
    medium.filename = "#{medium.video}.jpg"
    begin
      medium.base_sixty_four = Base64.encode64(downloaded_image.open.read)
      downloaded_image.unlink
    rescue NoMethodError
      medium.base_sixty_four = Base64.encode64(downloaded_image)
    end
    medium.attach_file unless medium.file.attached?
  end
end
