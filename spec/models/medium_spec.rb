# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Medium, type: :model) do
  it { is_expected.to(have_many(:stop_media)) }
  it { is_expected.to(have_many(:stops)) }

  context 'video' do
    it 'gets image from youtube and sets embed' do
      medium = create(:medium, video: 'F9ULbmCvmxY', base_sixty_four: nil, video_provider: 'youtube')
      expect(medium.embed).to(eq("//www.youtube.com/embed/#{medium.video}"))
      expect(medium.file.attached?).to(be(true))
    end

    it 'gets image from youtube when downloaded image is a StringIO object and sets embed' do
      file = File.open(Rails.root + 'spec/factories/images/atl.png')
      string_io = StringIO.new(file.read)
      base64 = VideoProps.encode_image(string_io)
      medium = create(:medium, base_sixty_four: base64)
      expect(medium.file.attached?).to(be(true))
    end

    it 'gets nothing when YouTube video is not found' do
      medium = create(:medium, video: 'CvmxYF9ULbm', base_sixty_four: nil, video_provider: 'youtube')
      expect(medium.embed).to(be_nil)
      expect(medium.provider).to(be_nil)
      expect(medium.file.attached?).to(be(false))
    end

    it 'gets image from vimeo and sets embed' do
      medium = create(:medium, video: '310645255', base_sixty_four: nil, video_provider: 'vimeo')
      expect(medium.embed).to(eq("//player.vimeo.com/video/#{medium.video}"))
      expect(medium.file.attached?).to(be(true))
    end

    it 'gets image from soundcloud and sets embed' do
      iframe = '<iframe width="100%" height="300" scrolling="no" frameborder="no" allow="autoplay" src="https://w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/457871163&color=%23ff5500&auto_play=false&hide_related=false&show_comments=true&show_user=true&show_reposts=false&show_teaser=true&visual=true"></iframe><div style="font-size: 10px; color: #cccccc;line-break: anywhere;word-break: normal;overflow: hidden;white-space: nowrap;text-overflow: ellipsis; font-family: Interstate,Lucida Grande,Lucida Sans Unicode,Lucida Sans,Garuda,Verdana,Tahoma,sans-serif;font-weight: 100;"><a href="https://soundcloud.com/fiendbassy" title="FiendBassy" target="_blank" style="color: #cccccc; text-decoration: none;">FiendBassy</a> · <a href="https://soundcloud.com/fiendbassy/boca-raton-feat-a-ap-ferg" title="Boca Raton (with A$AP Ferg)" target="_blank" style="color: #cccccc; text-decoration: none;">Boca Raton (with A$AP Ferg)</a></div>'
      medium = create(:medium, video: iframe, base_sixty_four: nil, video_provider: 'soundcloud')
      expect(medium.embed).to(eq("//w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/#{medium.video}&color=%23ff5500&auto_play=false&hide_related=true&show_comments=false&show_user=false&show_reposts=false&show_teaser=false&visual=true&sharing=false"))
      expect(medium.file.attached?).to(be(true))
      expect(medium.title).to(eq('FiendBassy: Boca Raton (with A$AP Ferg)'))
    end

    it 'gets title and embed from sketchfab full embed code' do
      iframe = '<div class="sketchfab-embed-wrapper"> <iframe title="Funerary Stela With Letter To Dead (D Stretch)" frameborder="0" allowfullscreen mozallowfullscreen="true" webkitallowfullscreen="true" allow="autoplay; fullscreen; xr-spatial-tracking" xr-spatial-tracking execution-while-out-of-viewport execution-while-not-rendered web-share src="https://sketchfab.com/models/4b570878a3cc4ca786af824a03ada414/embed"> </iframe> <p style="font-size: 13px; font-weight: normal; margin: 5px; color: #4A4A4A;"> <a href="https://sketchfab.com/3d-models/funerary-stela-with-letter-to-dead-d-stretch-4b570878a3cc4ca786af824a03ada414?utm_medium=embed&utm_campaign=share-popup&utm_content=4b570878a3cc4ca786af824a03ada414" target="_blank" rel="nofollow" style="font-weight: bold; color: #1CAAD9;"> Funerary Stela With Letter To Dead (D Stretch) </a> by <a href="https://sketchfab.com/iuegypt?utm_medium=embed&utm_campaign=share-popup&utm_content=4b570878a3cc4ca786af824a03ada414" target="_blank" rel="nofollow" style="font-weight: bold; color: #1CAAD9;"> iuegypt </a> on <a href="https://sketchfab.com?utm_medium=embed&utm_campaign=share-popup&utm_content=4b570878a3cc4ca786af824a03ada414" target="_blank" rel="nofollow" style="font-weight: bold; color: #1CAAD9;">Sketchfab</a></p></div>'
      medium = create(:medium, video: iframe, base_sixty_four: nil, video_provider: 'sketchfab')
      expect(medium.title).to(eq('A Sketchfab Model'))
      expect(medium.embed).to(eq('//sketchfab.com/models/4b570878a3cc4ca786af824a03ada414/embed'))
      expect(medium.filename).to(eq('fd4348dc5c7f48eea5c0d0b8ef376f8b.jpeg'))
      expect(medium.file.attached?).to(be(true))
    end

    it 'resolves sketchfab short URL through redirect chain to get model id' do
      stub_request(:head, 'https://skfb.ly/owuDQ')
        .to_return(status: 301, headers: { 'Location' => 'https://sketchfab.com:443/s/owuDQ' })
      stub_request(:head, 'https://sketchfab.com:443/s/owuDQ')
        .to_return(status: 301, headers: { 'Location' => 'https://sketchfab.com/3d-models/apis-bull-statuette-4b570878a3cc4ca786af824a03ada414' })
      stub_request(:head, 'https://sketchfab.com/3d-models/apis-bull-statuette-4b570878a3cc4ca786af824a03ada414')
        .to_return(status: 200)

      medium = create(:medium, video: 'https://skfb.ly/owuDQ', base_sixty_four: nil, video_provider: 'sketchfab')
      expect(medium.embed).to(eq('//sketchfab.com/models/4b570878a3cc4ca786af824a03ada414/embed'))
      expect(medium.title).to(eq('A Sketchfab Model'))
      expect(medium.video).to(eq('4b570878a3cc4ca786af824a03ada414'))
      expect(medium.file.attached?).to(be(true))
    end

    it 'resolves unknown embed' do
      medium = create(:medium, video: '//3d-api.si.edu/voyager/3d_package:a1651b35', base_sixty_four: nil, video_provider: 'unknown')
      expect(medium.embed).to(eq('//3d-api.si.edu/voyager/3d_package:a1651b35'))
      expect(medium.title).to(eq('A Model'))
      expect(medium.video).to(eq('//3d-api.si.edu/voyager/3d_package:a1651b35'))
      expect(medium.file.attached?).to(be(true))
    end

    it 'gets title and embed from sketchfab link' do
      medium = create(:medium, video: 'https://sketchfab.com/models/4b570878a3cc4ca786af824a03ada414/embed', base_sixty_four: nil, video_provider: 'sketchfab')
      expect(medium.title).to(eq('A Sketchfab Model'))
      expect(medium.embed).to(eq('//sketchfab.com/models/4b570878a3cc4ca786af824a03ada414/embed'))
      expect(medium.filename).to(eq('fd4348dc5c7f48eea5c0d0b8ef376f8b.jpeg'))
      expect(medium.video).to(eq('4b570878a3cc4ca786af824a03ada414'))
      expect(medium.file.attached?).to(be(true))
    end

    it 'gets title and embed from matterport link' do
      medium = create(:medium, video: 'matterport_id', base_sixty_four: nil, video_provider: 'matterport')
      expect(medium.title).to(eq('A Matterport Model'))
      expect(medium.embed).to(eq('//my.matterport.com/show/?m=matterport_id'))
      expect(medium.filename).to(eq('matterport_id.jpg'))
      expect(medium.video).to(eq('matterport_id'))
      expect(medium.file.attached?).to(be(true))
    end

    it 'gets title and embed from sketchfab model number' do
      medium = create(
        :medium,
        base_sixty_four: nil,
        video_provider: 'sketchfab',
        filename: '4b570878a3cc4ca786af824a03ada414.jpg',
        video: '4b570878a3cc4ca786af824a03ada414',
      )
      expect(medium.title).to(eq('A Sketchfab Model'))
      expect(medium.embed).to(eq('//sketchfab.com/models/4b570878a3cc4ca786af824a03ada414/embed'))
      expect(medium.filename).to(eq('fd4348dc5c7f48eea5c0d0b8ef376f8b.jpeg'))
      expect(medium.file.attached?).to(be(true))
      expect(medium.search_data[:provider]).to(eq('sketchfab'))
    end

    it 'gets default image from when no image found for soundcloud and sets embed full' do
      stub_request(:get, %r{https://soundcloud\.com/oembed})
        .to_return(status: 200, body: '{"thumbnail_url":null}', headers: { 'Content-Type' => 'application/json' })
      iframe = '<iframe width="100%" height="300" scrolling="no" frameborder="no" allow="autoplay" src="https://w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/431162745&color=%23ff5500&auto_play=false&hide_related=false&show_comments=true&show_user=true&show_reposts=false&show_teaser=true&visual=true"></iframe><div style="font-size: 10px; color: #cccccc;line-break: anywhere;word-break: normal;overflow: hidden;white-space: nowrap;text-overflow: ellipsis; font-family: Interstate,Lucida Grande,Lucida Sans Unicode,Lucida Sans,Garuda,Verdana,Tahoma,sans-serif;font-weight: 100;"><a href="https://soundcloud.com/user-270843798" title="Emory Center for Digital Scholarship" target="_blank" style="color: #cccccc; text-decoration: none;">Emory Center for Digital Scholarship</a> · <a href="https://soundcloud.com/user-270843798/6-subsatellite-launch" target="_blank" style="color: #cccccc; text-decoration: none;">Subsatellite Launch</a></div>'
      medium = create(:medium, video: iframe, base_sixty_four: nil, video_provider: 'soundcloud')
      expect(medium.embed).to(eq("//w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/#{medium.video}&color=%23ff5500&auto_play=false&hide_related=true&show_comments=false&show_user=false&show_reposts=false&show_teaser=false&visual=true&sharing=false"))
      expect(medium.file.attached?).to(be(true))
      expect(medium.title).to(eq('Emory Center for Digital Scholarship'))
    end

    it 'replaces file for video' do
      medium = create(:medium, video: 'F9ULbmCvmxY', base_sixty_four: nil, video_provider: 'youtube')
      original_checksum = medium.file.blob.checksum
      expect(original_checksum).to(eq(Digest::MD5.file(Rails.root.join('spec/factories/images/0.jpg')).base64digest))
      medium.update(base_sixty_four: File.read(Rails.root.join('spec/factories/images/png_base64.txt')))
      expect(medium.file.blob.checksum).not_to(eq(original_checksum))
      expect(medium.file.blob.checksum).to(eq(Digest::MD5.file(Rails.root.join('spec/factories/images/atl.png')).base64digest))
      expect(medium.search_data[:provider]).to(eq('youtube'))
    end

    it 'updates title and caption of video' do
      medium = create(:medium, video: 'F9ULbmCvmxY', base_sixty_four: nil, video_provider: 'youtube')
      expect(medium.title).to(include('Goodie'))
      expect(medium.caption).to(include('Goodie'))
      medium.update(title: 'Outkast')
      medium.update(caption: 'GOATs')
      expect(medium.title).not_to(include('Goodie'))
      expect(medium.caption).not_to(include('Goodie'))
      expect(medium.title).to(include('Outkast'))
      expect(medium.caption).to(include('GOATs'))
      # medium.update(base_sixty_four: File.read(Rails.root.join('spec/factories/images/png_base64.txt')))
      # expect(medium.file.blob.checksum).not_to eq(original_checksum)
      # expect(medium.file.blob.checksum).to eq(Digest::MD5.file(Rails.root.join('spec/factories/images/atl.png')).base64digest)
    end

    it 'skips video_props when provider in nil' do
      medium = create(:medium, video: 'ACod3', base_sixty_four: nil)
      expect(medium.file.attached?).to(be(false))
    end
  end

  context 'when creating images' do
    it 'creates a medium record with attachment' do
      poo = nil
      File.open(Rails.root.join('spec/factories/images/atl_base64.txt'), 'r') do |b64|
        poo = b64.read
      end
      described_class.create(base_sixty_four: poo, filename: 'atl.png')
      medium = described_class.find_by(filename: 'atl.png')
      expect(medium.filename).to(eq('atl.png'))
    end

    it 'sets widths for variants' do
      medium = create(
        :medium,
        filename: Faker::File.file_name(dir: '', ext: 'jpg', directory_separator: ''),
        video: nil,
      )
      medium = described_class.find(medium.id)
      medium.save
      expect(medium).not_to(be_nil)
      # expect(medium.lqip_width).not_to be nil
    end

    it 'saves a gif' do
      medium = create(
        :medium,
        filename: Faker::File.file_name(dir: '', ext: 'gif', directory_separator: ''),
        base_sixty_four: File.read(Rails.root.join('spec/factories/images/gif_base64.txt')),
        video: nil,
      )

      expect(medium.file.blob.checksum).to(eq('4fqkSXu+qjQuQWCms8xBBQ=='))
    end
  end
end
