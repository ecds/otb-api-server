# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(OpenGeographies::DeserializerV1) do
  def og_stop(name, order: nil)
    {
      uuid: SecureRandom.uuid,
      slug: name.parameterize,
      name:,
      geo: { point: { lat: 33.7, lon: -84.3 } },
      order:,
    }.compact
  end

  def titles(stops)
    described_class.new(stops:).call[:stops].pluck(:title)
  end

  it 'puts stops in their Open Geographies order and numbers them from 1' do
    result = described_class.new(stops: [og_stop('C', order: 30), og_stop('A', order: 10), og_stop('B', order: 20)]).call
    expect(result[:stops].pluck(:title)).to(eq(['A', 'B', 'C']))
    expect(result[:stops].pluck(:position)).to(eq([1, 2, 3]))
    expect(result[:stops].first[:next][:title]).to(eq('B'))
  end

  it 'keeps the listed order for stops with the same order' do
    expect(titles([og_stop('First', order: 1), og_stop('Second', order: 1)])).to(eq(['First', 'Second']))
  end

  it 'puts stops without an order last, in their listed order' do
    expect(titles([og_stop('X'), og_stop('B', order: 2), og_stop('Y'), og_stop('A', order: 1)]))
      .to(eq(['A', 'B', 'X', 'Y']))
  end

  it 'gives embedded media the same fields as a natively added medium' do
    stop = og_stop('Adgateville').merge(media: [{
      uuid: 'bb4df2e7-9868-45f1-a831-9aa355fdf987',
      name: 'Adgateville Baptist - 3D Tour',
      embed_url: 'https://my.matterport.com/show/?m=eTtau15mrcK',
      content_url: 'https://iiif.example.org/resources/abc/inline',
      media_type: 'model3d',
    }])
    medium = described_class.new(stops: [stop]).call[:stops].first[:media].first
    expect(medium).to(include(
      provider: 'matterport',
      embed_id: 'eTtau15mrcK',
      video: 'eTtau15mrcK',
      embed: '//my.matterport.com/show/?m=eTtau15mrcK',
    ))
    expect(medium[:files].values.uniq).to(eq(['https://my.matterport.com/api/v2/player/models/eTtau15mrcK/thumb/']))
  end

  it "doesn't look up thumbnails for images that come with one" do
    stop = og_stop('Academy').merge(media: [{ uuid: 'y', name: 'Front', thumbnail: 'https://example.org/t.jpg' }])
    allow(OpenGeographies::MediaResolver).to(receive(:new).and_call_original)
    medium = described_class.new(stops: [stop]).call[:stops].first[:media].first
    expect(medium[:files][:mobile]).to(eq('https://example.org/t.jpg'))
    expect(OpenGeographies::MediaResolver).not_to(have_received(:new))
  end

  it 'leaves images without embed fields' do
    stop = og_stop('Academy').merge(media: [{ uuid: 'x', name: 'Front', thumbnail: 'https://example.org/t.jpg' }])
    medium = described_class.new(stops: [stop]).call[:stops].first[:media].first
    expect(medium).to(include(embed: nil, embed_id: nil))
  end

  it 'shows OG images without alt text as decorative, but flags them' do
    stop = og_stop('Academy').merge(media: [
      { uuid: 'a', name: 'Front', thumbnail: 'https://example.org/a.jpg', alt_text: 'Academy Baptist from the road' },
      { uuid: 'b', name: 'Pews', thumbnail: 'https://example.org/b.jpg' },
    ])
    media = described_class.new(stops: [stop]).call[:stops].first[:media]
    expect(media[0]).to(include(alt_text: 'Academy Baptist from the road', decorative: false, missing_alt_text: false))
    expect(media[1]).to(include(alt_text: nil, decorative: true, missing_alt_text: true))
  end
end
