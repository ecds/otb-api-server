# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(UrlResolver) do
  describe '.resolve' do
    it 'returns the url immediately when no redirect' do
      stub_request(:head, 'https://example.com/page')
        .to_return(status: 200)
      expect(described_class.resolve('https://example.com/page')).to(eq('https://example.com/page'))
    end

    it 'follows a single redirect' do
      stub_request(:head, 'https://short.ly/abc')
        .to_return(status: 301, headers: { 'Location' => 'https://example.com/final' })
      stub_request(:head, 'https://example.com/final')
        .to_return(status: 200)
      expect(described_class.resolve('https://short.ly/abc')).to(eq('https://example.com/final'))
    end

    it 'follows a chain of redirects' do
      stub_request(:head, 'https://short.ly/abc')
        .to_return(status: 301, headers: { 'Location' => 'https://example.com/step2' })
      stub_request(:head, 'https://example.com/step2')
        .to_return(status: 302, headers: { 'Location' => 'https://example.com/final' })
      stub_request(:head, 'https://example.com/final')
        .to_return(status: 200)
      expect(described_class.resolve('https://short.ly/abc')).to(eq('https://example.com/final'))
    end
  end
end
