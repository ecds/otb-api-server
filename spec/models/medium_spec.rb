# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Medium, type: :model) do
  it { is_expected.to(have_many(:stop_media)) }
  it { is_expected.to(have_many(:stops)) }

  context 'when embed_id is present' do
    it 'gets image from youtube and sets embed' do
      medium = create(:medium, video: 'F9ULbmCvmxY', embed_id: 'F9ULbmCvmxY', base_sixty_four: nil, video_provider: 'youtube')
      expect(medium.embed).to(eq("//www.youtube.com/embed/#{medium.embed_id}"))
      expect(medium.file.attached?).to(be(true))
    end

    it 'gets nothing when YouTube video is not found' do
      medium = create(:medium, video: 'CvmxYF9ULbm', embed_id: 'CvmxYF9ULbm', base_sixty_four: nil, video_provider: 'youtube')
      expect(medium.embed).to(be_nil)
      expect(medium.provider).to(be_nil)
      expect(medium.file.attached?).to(be(false))
    end

    it 'gets image from vimeo and sets embed' do
      medium = create(:medium, video: '310645255', embed_id: '310645255', base_sixty_four: nil, video_provider: 'vimeo')
      expect(medium.embed).to(eq("//player.vimeo.com/video/#{medium.embed_id}"))
      expect(medium.file.attached?).to(be(true))
    end

    it 'gets image from soundcloud and sets embed' do
      medium = create(:medium, video: '457871163', embed_id: '457871163', base_sixty_four: nil, video_provider: 'soundcloud')
      expect(medium.embed).to(eq('//w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/457871163&color=%23ff5500&auto_play=false&hide_related=true&show_comments=false&show_user=false&show_reposts=false&show_teaser=false&visual=true&sharing=false'))
      expect(medium.file.attached?).to(be(true))
      expect(medium.title).to(eq('A SoundCloud Track'))
    end

    it 'gets title and embed from sketchfab model id' do
      medium = create(:medium, video: '4b570878a3cc4ca786af824a03ada414', embed_id: '4b570878a3cc4ca786af824a03ada414', base_sixty_four: nil, video_provider: 'sketchfab')
      expect(medium.title).to(eq('A Sketchfab Model'))
      expect(medium.embed).to(eq('//sketchfab.com/models/4b570878a3cc4ca786af824a03ada414/embed'))
      expect(medium.filename).to(eq('fd4348dc5c7f48eea5c0d0b8ef376f8b.jpeg'))
      expect(medium.file.attached?).to(be(true))
    end

    it 'resolves unknown embed' do
      medium = create(:medium, video: '//3d-api.si.edu/voyager/3d_package:a1651b35', embed_id: '//3d-api.si.edu/voyager/3d_package:a1651b35', base_sixty_four: nil, video_provider: 'unknown')
      expect(medium.embed).to(eq('//3d-api.si.edu/voyager/3d_package:a1651b35'))
      expect(medium.title).to(eq('A Model'))
      expect(medium.embed_id).to(eq('//3d-api.si.edu/voyager/3d_package:a1651b35'))
      expect(medium.file.attached?).to(be(true))
    end

    it 'gets embed from morphosource manifest uuid' do
      uuid = '81902b5f-f5d6-4c59-9fcb-84cf7489819f'
      medium = create(:medium, video: uuid, embed_id: uuid, base_sixty_four: nil, video_provider: 'morphosource')
      expect(medium.embed).to(eq("//www.morphosource.org/uv.html#?manifest=/manifests/#{uuid}&c=0&m=0&cv=0"))
      expect(medium.title).to(eq('Fragment [Mesh] [StrLight]'))
      expect(medium.caption).to(eq('Italic terra sigillata fragment'))
      expect(medium.file.attached?).to(be(true))
    end

    it 'gets title and embed from matterport link' do
      medium = create(:medium, video: 'matterport_id', embed_id: 'matterport_id', base_sixty_four: nil, video_provider: 'matterport')
      expect(medium.title).to(eq('A Matterport Model'))
      expect(medium.embed).to(eq('//my.matterport.com/show/?m=matterport_id'))
      expect(medium.filename).to(eq('matterport_id.jpg'))
      expect(medium.embed_id).to(eq('matterport_id'))
      expect(medium.file.attached?).to(be(true))
    end

    it 'gets title and embed from sketchfab model number' do
      medium = create(
        :medium,
        base_sixty_four: nil,
        video_provider: 'sketchfab',
        filename: '4b570878a3cc4ca786af824a03ada414.jpg',
        video: '4b570878a3cc4ca786af824a03ada414',
        embed_id: '4b570878a3cc4ca786af824a03ada414',
      )
      expect(medium.title).to(eq('A Sketchfab Model'))
      expect(medium.embed).to(eq('//sketchfab.com/models/4b570878a3cc4ca786af824a03ada414/embed'))
      expect(medium.filename).to(eq('fd4348dc5c7f48eea5c0d0b8ef376f8b.jpeg'))
      expect(medium.file.attached?).to(be(true))
      expect(medium.search_data[:provider]).to(eq('sketchfab'))
    end

    it 'gets default image from when no image found for soundcloud and sets embed full' do
      stub_request(:get, %r{https://soundcloud\.com/oembed})
        .to_return(status: 200, body: '{"title": "Subsatellite Launch", "thumbnail_url":null}', headers: { 'Content-Type' => 'application/json' })
      medium = create(:medium, video: '431162745', embed_id: '431162745', base_sixty_four: nil, video_provider: 'soundcloud')
      expect(medium.embed).to(eq('//w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/431162745&color=%23ff5500&auto_play=false&hide_related=true&show_comments=false&show_user=false&show_reposts=false&show_teaser=false&visual=true&sharing=false'))
      expect(medium.file.attached?).to(be(true))
      expect(medium.title).to(eq('Subsatellite Launch'))
    end

    it 'replaces file for video' do
      medium = create(:medium, video: 'F9ULbmCvmxY', embed_id: 'F9ULbmCvmxY', base_sixty_four: nil, video_provider: 'youtube')
      original_checksum = medium.file.blob.checksum
      expect(original_checksum).to(eq(Digest::MD5.file(Rails.root.join('spec/factories/images/0.jpg')).base64digest))
      medium.update(base_sixty_four: File.read(Rails.root.join('spec/factories/images/png_base64.txt')))
      expect(medium.file.blob.checksum).not_to(eq(original_checksum))
      expect(medium.file.blob.checksum).to(eq(Digest::MD5.file(Rails.root.join('spec/factories/images/atl.png')).base64digest))
      expect(medium.search_data[:provider]).to(eq('youtube'))
    end

    it 'updates title and caption of video' do
      medium = create(:medium, video: 'F9ULbmCvmxY', embed_id: 'F9ULbmCvmxY', base_sixty_four: nil, video_provider: 'youtube')
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

    it 'skips embed_props when provider is nil' do
      medium = create(:medium, video: 'ACod3', embed_id: 'ACod3', base_sixty_four: nil)
      expect(medium.file.attached?).to(be(false))
    end
  end

  describe '#orphaned' do
    it 'is true when not associated with any tour or stop' do
      medium = create(:medium)
      expect(medium.orphaned).to(be(true))
    end

    it 'is false when associated with a stop' do
      stop = create(:stop)
      medium = create(:medium, stops: [stop])
      expect(medium.orphaned).to(be(false))
    end

    it 'is false when associated with a tour' do
      tour = create(:tour)
      medium = create(:medium, tours: [tour])
      expect(medium.orphaned).to(be(false))
    end
  end

  describe '#published' do
    it 'is false when orphaned' do
      medium = create(:medium)
      expect(medium.published).to(be(false))
    end

    it 'is true when associated with a published tour' do
      tour = create(:tour, published: true)
      medium = create(:medium, tours: [tour])
      expect(medium.published).to(be(true))
    end

    it 'is true when associated with a stop on a published tour' do
      tour = create(:tour, published: true)
      stop = create(:stop, tours: [tour])
      medium = create(:medium, stops: [stop])
      expect(medium.published).to(be(true))
    end
  end

  describe '#files' do
    it 'returns same url for all variants when file is a gif' do
      medium = create(
        :medium,
        filename: Faker::File.file_name(dir: '', ext: 'gif', directory_separator: ''),
        base_sixty_four: File.read(Rails.root.join('spec/factories/images/gif_base64.txt')),
        video: nil,
      )
      files = medium.files
      expect(files[:mobile]).to(include('/active_storage/disk/'))
      expect(files[:desktop]).to(include('/active_storage/disk/'))
      expect(files[:lqip]).to(include('/active_storage/disk/'))
    end

    it 'returns nil when no file attached' do
      medium = build(:medium, base_sixty_four: nil, video: nil, embed_id: nil)
      expect(medium.files).to(be_nil)
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
