# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(VideoProviders) do
  describe '.detect' do
    it 'names the provider a URL belongs to' do
      expect(described_class.detect('https://youtu.be/F9ULbmCvmxY')).to(eq('youtube'))
      expect(described_class.detect('https://my.matterport.com/show/?m=abc')).to(eq('matterport'))
      expect(described_class.detect('https://example.org/viewer')).to(be_nil)
    end
  end

  describe '.class_for' do
    it 'falls back to the generic embed' do
      expect(described_class.class_for('vimeo')).to(eq(VideoProviders::Vimeo))
      expect(described_class.class_for('unknown')).to(eq(VideoProviders::Base))
      expect(described_class.class_for(nil)).to(eq(VideoProviders::Base))
    end
  end

  describe '.embed_id_from' do
    {
      VideoProviders::Youtube => {
        'https://www.youtube.com/watch?v=F9ULbmCvmxY' => 'F9ULbmCvmxY',
        'https://www.youtube.com/watch?feature=share&v=F9ULbmCvmxY' => 'F9ULbmCvmxY',
        'https://youtu.be/F9ULbmCvmxY?t=30' => 'F9ULbmCvmxY',
        'https://www.youtube.com/shorts/F9ULbmCvmxY' => 'F9ULbmCvmxY',
      },
      VideoProviders::Vimeo => { 'https://vimeo.com/310645255' => '310645255', 'https://player.vimeo.com/video/310645255' => '310645255' },
      VideoProviders::Soundcloud => { 'https://api.soundcloud.com/tracks/457871163' => '457871163' },
      VideoProviders::Sketchfab => {
        'https://sketchfab.com/models/4b570878a3cc4ca786af824a03ada414' => '4b570878a3cc4ca786af824a03ada414',
        'https://sketchfab.com/3d-models/old-church-4b570878a3cc4ca786af824a03ada414' => '4b570878a3cc4ca786af824a03ada414',
      },
      VideoProviders::Matterport => { 'https://my.matterport.com/show/?m=eTtau15mrcK' => 'eTtau15mrcK' },
    }.each do |provider, urls|
      urls.each do |url, id|
        it "finds #{id} in #{url}" do
          expect(provider.embed_id_from(url)).to(eq(id))
        end
      end
    end

    it 'has no id for generic embeds or MorphoSource' do
      expect(VideoProviders::Base.embed_id_from('https://example.org/x')).to(be_nil)
      expect(VideoProviders::Morphosource.embed_id_from('https://www.morphosource.org/concern/media/1')).to(be_nil)
    end
  end

  describe '#thumbnail_url' do
    def thumbnail(provider, id)
      provider.new(VideoProviders::Item.new(id)).thumbnail_url
    end

    it 'gives the URL without downloading the image' do
      image = stub_request(:get, 'https://img.youtube.com/vi/F9ULbmCvmxY/0.jpg')
      expect(thumbnail(VideoProviders::Youtube, 'F9ULbmCvmxY')).to(eq('https://img.youtube.com/vi/F9ULbmCvmxY/0.jpg'))
      expect(image).not_to(have_been_requested)
    end

    it "reads the page's og:image for Sketchfab" do
      expect(thumbnail(VideoProviders::Sketchfab, '4b570878a3cc4ca786af824a03ada414')).to(include('media.sketchfab.com'))
    end

    it "builds Matterport's from the id, without fetching the page" do
      page = stub_request(:get, %r{my\.matterport\.com/show})
      expect(thumbnail(VideoProviders::Matterport, 'eTtau15mrcK'))
        .to(eq('https://my.matterport.com/api/v2/player/models/eTtau15mrcK/thumb/'))
      expect(page).not_to(have_been_requested)
    end

    it 'has none for MorphoSource' do
      expect(thumbnail(VideoProviders::Morphosource, 'abc')).to(be_nil)
    end
  end
end
