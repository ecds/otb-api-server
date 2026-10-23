# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(OpenGeographies::Source) do
  let(:url) { 'https://og.example.org/api/v1/tours/test-tour' }
  let(:fixture) { JSON.parse(file_fixture('open_geographies.json').read, symbolize_names: true) }
  let(:context) { 'https://opengeographies.org/api/v1/context.json' }

  def respond_with(document, status: 200)
    stub_request(:get, url).to_return(
      status:,
      body: document.is_a?(String) ? document : document.to_json,
      headers: { 'Content-Type' => 'application/json' },
    )
  end

  def preview(**)
    described_class.new(url).call(**)
  end

  def error_message
    preview
  rescue described_class::Error => e
    e.message
  end

  it 'turns the tour document into stops' do
    respond_with(fixture)
    result = preview
    expect(result[:version]).to(eq('v1'))
    expect(result[:context]).to(eq(context))
    expect(result[:stop_count]).to(eq(4))
    # Sorted by each stop's Open Geographies order, not the listed order.
    expect(result[:stops].first).to(include(title: 'Oconee Baptist', position: 1))
    expect(result[:bounds]).to(include(:north, :south, :east, :west))
    expect(result[:fetched_at]).to(be_present)
  end

  def with_stop_contexts(*contexts)
    stops = fixture[:stops].each_with_index.map do |stop, index|
      value = contexts[index % contexts.size]
      value ? stop.merge('@context': value) : stop.except(:'@context')
    end
    fixture.merge(stops:)
  end

  it 'rejects a response whose stops have no Open Geographies @context' do
    respond_with(with_stop_contexts(nil).merge('@context': context))
    expect(error_message).to(match(/stops have no Open Geographies @context/))
  end

  it 'leaves out a stop without an Open Geographies @context and says so' do
    document = with_stop_contexts(context, context, 'https://schema.org', context)
    respond_with(document)
    result = preview
    expect(result[:stop_count]).to(eq(3))
    expect(result[:problems]).to(include(
      "#{document[:stops][2][:name]} has no Open Geographies @context, so it can't be shown.",
    ))
  end

  it 'rejects a version it cannot read yet' do
    respond_with(with_stop_contexts('https://opengeographies.org/api/v2/context.json'))
    expect(error_message).to(eq("Open Geographies v2 isn't supported yet."))
  end

  it 'rejects stops on different versions' do
    respond_with(with_stop_contexts(context, 'https://opengeographies.org/api/v2/context.json'))
    expect(error_message).to(eq('The stops use different Open Geographies versions (v1, v2).'))
  end

  it 'flags media listed more than once on a stop' do
    stops = fixture[:stops].dup
    medium = { uuid: 'abc', name: 'Front', thumbnail: 'https://example.org/t.jpg' }
    stops[0] = stops[0].merge(media: [medium, medium])
    respond_with(fixture.merge(stops:))
    expect(preview[:problems]).to(include("#{stops[0][:name]} lists a medium more than once."))
  end

  it 'leaves out stops without a location and says so' do
    stops = fixture[:stops].dup
    stops[1] = stops[1].except(:geo)
    respond_with(fixture.merge(stops:))
    result = preview
    expect(result[:stop_count]).to(eq(3))
    expect(result[:problems]).to(include("#{stops[1][:name]} has no location, so it can't be shown."))
  end

  it 'gives each stop a description that is safe to show as HTML' do
    stops = fixture[:stops].dup
    stops[0] = stops[0].merge(description: '<p onclick="steal()">Hi <a href="/x">there</a></p><script>steal()</script>')
    respond_with(fixture.merge(stops:))
    html = preview[:stops].find { |stop| stop[:id] == stops[0][:uuid] }[:description_html]
    expect(html).to(include('<p>Hi <a href="/x">there</a></p>'))
    expect(html).not_to(include('onclick'))
    expect(html).not_to(include('<script'))
  end

  it 'counts images without alt text' do
    stops = fixture[:stops].map { |stop| stop.merge(media: []) }
    stops[0] = stops[0].merge(media: [{ uuid: 'a', name: 'A', thumbnail: 'https://example.org/a.jpg' }])
    stops[1] = stops[1].merge(media: [
      { uuid: 'b', name: 'B', thumbnail: 'https://example.org/b.jpg' },
      { uuid: 'c', name: 'C', thumbnail: 'https://example.org/c.jpg', alt_text: 'Described' },
    ])
    respond_with(fixture.merge(stops:))
    expect(preview[:problems]).to(include(
      "2 images have no alt text, so they're shown as decorative. Add alt text in Open Geographies.",
    ))
  end

  it 'flags stops that share an id' do
    stops = fixture[:stops].dup
    stops[1] = stops[1].merge(uuid: stops[0][:uuid])
    respond_with(fixture.merge(stops:))
    expect(preview[:problems]).to(include("2 stops share the id #{stops[0][:uuid]}."))
  end

  it 'reports an error response from Open Geographies' do
    respond_with('', status: 503)
    expect(error_message).to(eq('Open Geographies responded with 503.'))
  end

  it 'reports a response that is not JSON' do
    respond_with('<html>Not found</html>')
    expect(error_message).to(eq('The Open Geographies response is not valid JSON.'))
  end

  it 'reports a timeout' do
    stub_request(:get, url).to_timeout
    expect(error_message).to(eq('Open Geographies took too long to respond.'))
  end

  it 'only fetches http and https URLs' do
    expect { described_class.new('file:///etc/passwd').call }
      .to(raise_error(described_class::Error, /must start with http/))
  end

  it 'requires a URL' do
    expect { described_class.new(nil).call }.to(raise_error(described_class::Error, /No Open Geographies URL/))
  end

  describe 'allowed hosts' do
    around do |example|
      original = ENV.fetch('OPEN_GEOGRAPHIES_HOSTS', nil)
      example.run
    ensure
      ENV['OPEN_GEOGRAPHIES_HOSTS'] = original
    end

    def problem(url, hosts)
      ENV['OPEN_GEOGRAPHIES_HOSTS'] = hosts
      described_class.url_problem(url)
    end

    it 'accepts a listed host' do
      expect(problem('https://og.example.org/tours/1', 'og.example.org')).to(be_nil)
    end

    it 'accepts subdomains of a wildcard entry, but not the bare domain' do
      expect(problem('https://api.atlas.example/tours/1', '*.atlas.example')).to(be_nil)
      expect(problem('https://atlas.example/tours/1', '*.atlas.example')).to(match(/isn't an allowed/))
    end

    it 'refuses look-alike hosts' do
      expect(problem('https://og.example.org.evil.test/x', 'og.example.org')).to(match(/isn't an allowed/))
      expect(problem('https://evilatlas.example/x', '*.atlas.example')).to(match(/isn't an allowed/))
    end

    it 'allows nothing when the list is unset' do
      expect(problem('https://og.example.org/tours/1', '')).to(eq("og.example.org isn't an allowed Open Geographies host."))
    end

    it 'never fetches from a host that is not allowed' do
      ENV['OPEN_GEOGRAPHIES_HOSTS'] = 'og.example.org'
      internal = stub_request(:get, 'http://169.254.169.254/latest/meta-data')
      expect { described_class.new('http://169.254.169.254/latest/meta-data').call }
        .to(raise_error(described_class::Error, /isn't an allowed/))
      expect(internal).not_to(have_been_requested)
    end
  end

  it "doesn't follow redirects, which could lead to another host" do
    stub_request(:get, url).to_return(status: 302, headers: { 'Location' => 'http://169.254.169.254/' })
    expect(error_message).to(match(/redirected to another address/))
  end

  describe 'caching' do
    before { allow(Rails).to(receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)) }

    it 'reuses a recent preview, and refetches when asked' do
      stub = respond_with(fixture)
      preview
      preview
      expect(stub).to(have_been_requested.once)
      preview(refresh: true)
      expect(stub).to(have_been_requested.twice)
    end

    it 'does not cache errors' do
      stub = respond_with('', status: 500)
      2.times { error_message }
      expect(stub).to(have_been_requested.twice)
    end
  end
end
