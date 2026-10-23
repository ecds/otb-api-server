# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(OpenGeographies::MediaResolver) do
  include ActiveSupport::Testing::TimeHelpers

  let(:content_url) { 'https://iiif.example.org/resources/abc/inline' }
  let(:matterport) do
    {
      uuid: SecureRandom.uuid,
      embed_url: 'https://my.matterport.com/show/?m=eTtau15mrcK',
      content_url:,
      media_type: 'model3d',
    }
  end
  let(:thumb) { 'https://my.matterport.com/api/v2/player/models/eTtau15mrcK/thumb/' }

  # A provider whose thumbnail comes from its page, to cover pages without one.
  let(:sketchfab_page) { 'https://sketchfab.com/models/4b570878a3cc4ca786af824a03ada414/embed' }
  let(:sketchfab) do
    {
      uuid: SecureRandom.uuid,
      embed_url: 'https://sketchfab.com/models/4b570878a3cc4ca786af824a03ada414',
      content_url:,
      media_type: 'model3d',
    }
  end

  def stub_sketchfab(image)
    body = image ? %(<html><head><meta property="og:image" content="#{image}"></head></html>) : '<html></html>'
    stub_request(:get, sketchfab_page).to_return(body:)
  end

  it "uses the provider's thumbnail for embedded media, not their content_url" do
    content = stub_request(:head, content_url)
    expect(described_class.new(matterport).call).to(have_attributes(provider: 'matterport', thumbnail_url: thumb))
    expect(content).not_to(have_been_requested)
  end

  it "builds Matterport's thumbnail without fetching its page" do
    page = stub_request(:get, %r{my\.matterport\.com/show})
    expect(described_class.new(matterport).call.thumbnail_url).to(eq(thumb))
    expect(page).not_to(have_been_requested)
  end

  it 'finds the thumbnail for every link shape the embed understands' do
    medium = { uuid: SecureRandom.uuid, embed_url: 'https://www.youtube.com/watch?feature=share&v=F9ULbmCvmxY' }
    expect(described_class.new(medium).call.thumbnail_url).to(eq('https://img.youtube.com/vi/F9ULbmCvmxY/0.jpg'))
  end

  it "doesn't use a content_url that isn't an image" do
    stub_sketchfab(nil)
    stub_request(:head, content_url).to_return(headers: { 'Content-Type' => 'model/gltf-binary' })
    expect(described_class.new(sketchfab).call.thumbnail_url).to(be_nil)
  end

  it 'uses a content_url that is an image when the provider has no thumbnail' do
    stub_sketchfab(nil)
    stub_request(:head, content_url).to_return(headers: { 'Content-Type' => 'image/jpeg' })
    expect(described_class.new(sketchfab).call.thumbnail_url).to(eq(content_url))
  end

  it 'tries again within the hour when no thumbnail was found' do
    stub_sketchfab(nil)
    stub_request(:head, content_url).to_return(status: 404)
    described_class.new(sketchfab).call

    travel(2.hours) do
      stub_sketchfab('https://media.sketchfab.com/t.jpg')
      expect(described_class.new(sketchfab).call.thumbnail_url).to(eq('https://media.sketchfab.com/t.jpg'))
    end
  end

  it 'keeps a thumbnail it found for 30 days' do
    page = stub_sketchfab('https://media.sketchfab.com/t.jpg')
    described_class.new(sketchfab).call
    travel(29.days) { described_class.new(sketchfab).call }
    expect(page).to(have_been_requested.once)
  end
end
