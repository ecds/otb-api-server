# frozen_string_literal: true

require 'open-uri'
require 'httparty'
require 'json'

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
      thumbnail_url = "#{metadata["thumbnail_url"].split("_")[0]}_#{thumbnail_width * scale_by}x#{thumbnail_height * scale_by}"
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
        return
      end
    when 'soundcloud'
      if medium.video.include?('iframe')
        embed_code = Nokogiri::HTML(medium.video)
        medium.title = embed_code.xpath('//a').map { |a| a[:title] }.compact.join(': ')
        medium.video = embed_code.xpath('//iframe', 'src').first['src'].split('&').first[%r{(.*tracks/)(.*)}, 2]
        medium.embed = "//w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/#{medium.video}&color=%23ff5500&auto_play=false&hide_related=true&show_comments=false&show_user=false&show_reposts=false&show_teaser=false&visual=true&sharing=false"
        track_url = embed_code.xpath('//a').last[:href]
        track_response = HTTParty.get("https://soundcloud.com/oembed?url=#{track_url}&format=json", format: 'plan')
        track_data = JSON.parse(track_response.body).deep_symbolize_keys!
        downloaded_image = if track_data[:thumbnail_url].nil?
          File.open(Rails.root.join('public/soundcloud.jpg').to_s).read
        else
          URI.open(track_data[:thumbnail_url])
        end
      end

    end

    return if downloaded_image.nil?

    medium.filename = "#{medium.video}.jpg"
    medium.base_sixty_four = encode_image(downloaded_image)
    medium.attach_file unless medium.file.attached?
  end

  def self.encode_image(downloaded_image)
    begin
      if downloaded_image.is_a?(StringIO)
        base_sixty_four = Base64.encode64(downloaded_image.read)
      else
        base_sixty_four = Base64.encode64(downloaded_image.open.read)
        downloaded_image.unlink
      end
    rescue NoMethodError
      base_sixty_four = Base64.encode64(downloaded_image)
    end
    base_sixty_four
  end
end
