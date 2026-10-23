# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(OpenGeographies::Embed) do
  def embed(url)
    described_class.call(url)
  end

  it 'builds the same iframe URL as a natively added medium' do
    {
      'https://www.youtube.com/watch?v=F9ULbmCvmxY' => ['youtube', 'F9ULbmCvmxY', '//www.youtube.com/embed/F9ULbmCvmxY'],
      'https://youtu.be/F9ULbmCvmxY?t=30' => ['youtube', 'F9ULbmCvmxY', '//www.youtube.com/embed/F9ULbmCvmxY'],
      'https://www.youtube.com/watch?feature=share&v=F9ULbmCvmxY' => ['youtube', 'F9ULbmCvmxY', '//www.youtube.com/embed/F9ULbmCvmxY'],
      'https://vimeo.com/76979871' => ['vimeo', '76979871', '//player.vimeo.com/video/76979871'],
      'https://player.vimeo.com/video/76979871' => ['vimeo', '76979871', '//player.vimeo.com/video/76979871'],
      'https://my.matterport.com/show/?m=eTtau15mrcK' => ['matterport', 'eTtau15mrcK', '//my.matterport.com/show/?m=eTtau15mrcK'],
      'https://sketchfab.com/3d-models/old-church-0123456789abcdef0123456789abcdef' =>
        ['sketchfab', '0123456789abcdef0123456789abcdef', '//sketchfab.com/models/0123456789abcdef0123456789abcdef/embed'],
    }.each do |url, (provider, embed_id, iframe)|
      expect(embed(url)).to(eq({ provider:, embed_id:, embed: iframe }), url)
    end
  end

  it 'uses the SoundCloud track id when there is one' do
    expect(embed('https://api.soundcloud.com/tracks/123456')).to(include(provider: 'soundcloud', embed_id: '123456'))
    expect(embed('https://api.soundcloud.com/tracks/123456')[:embed]).to(include('api.soundcloud.com/tracks/123456'))
  end

  it "plays any other SoundCloud link through SoundCloud's player" do
    result = embed('https://soundcloud.com/ecds/church-bells')
    expect(result[:embed]).to(eq('//w.soundcloud.com/player/?url=https%3A%2F%2Fsoundcloud.com%2Fecds%2Fchurch-bells&visual=true'))
  end

  it 'embeds other web addresses as they are' do
    expect(embed('https://example.org/viewer/1')).to(eq({ provider: nil, embed_id: nil, embed: 'https://example.org/viewer/1' }))
  end

  it 'refuses anything that is not a web address' do
    expect(embed('javascript:alert(1)')).to(be_nil)
    expect(embed('data:text/html,<script>x</script>')).to(be_nil)
    expect(embed(nil)).to(be_nil)
  end
end
