# frozen_string_literal: true

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
      downloaded_image = HTTParty.get(thumbnail_url).body
    when 'youtube'
      begin
        metadata = Yt::Video.new(id: medium.video)
        medium.title = metadata.title
        medium.caption = metadata.description
        medium.embed = "//www.youtube.com/embed/#{medium.video}"
        downloaded_image = HTTParty.get("https://img.youtube.com/vi/#{medium.video}/0.jpg").body
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
          HTTParty.get(track_data[:thumbnail_url]).body
        end
      end
    when 'sketchfab'
      embed_url = if medium.video.include?('iframe')
        embed_code = Nokogiri::HTML(medium.video)
        embed_code.xpath('//iframe').first[:src]
      elsif medium.video.ends_with?('embed')
        medium.video
      elsif medium.video.start_with?('http')
        model_id = UrlResolver.resolve(medium.video)[/[0-9a-f]{32}/]
        "https://sketchfab.com/models/#{model_id}/embed"
      else
        "https://sketchfab.com/models/#{medium.video}/embed"
      end

      doc = Nokogiri::HTML(HTTParty.get(embed_url).body)
      medium.title = doc.xpath('/html/head/meta[@property="og:title"]').first[:content]
      medium.embed = "//sketchfab.com#{URI.parse(embed_url).path}"
      medium.video = medium.embed.split('/')[-2]
      image_url = doc.xpath('/html/head/meta[@property="og:image"]').first[:content]
      medium.filename = File.basename(URI.parse(image_url).path)
      downloaded_image = HTTParty.get(image_url).body

    when 'matterport'
      medium.embed = "//my.matterport.com/show/?m=#{medium.video}"
      doc = Nokogiri::HTML(HTTParty.get('https:' + medium.embed).body)
      medium.title = doc.xpath('/html/head/meta[@property="og:title"]').first[:content]
      image_url = doc.xpath('/html/head/meta[@property="og:image"]').first[:content]
      medium.filename = medium.video + '.jpg'
      downloaded_image = HTTParty.get(image_url).body

    when 'unknown'
      url = medium.video.starts_with?('http') ? medium.video : "https:#{medium.video}"
      doc = Nokogiri::HTML(HTTParty.get(url).body)
      medium.title = doc.xpath('/html/head/title').first.text
      medium.embed = medium.video
      medium.filename = 'otblogo.png'
      downloaded_image = File.open(Rails.root.join('public/otblogo.png').to_s).read
    end

    return if downloaded_image.nil?

    medium.filename ||= "#{medium.video}.jpg"
    medium.base_sixty_four = encode_image(downloaded_image)
    medium.attach_file unless medium.file.attached?
  end

  def self.encode_image(downloaded_image)
    Base64.encode64(downloaded_image)
  end
end
