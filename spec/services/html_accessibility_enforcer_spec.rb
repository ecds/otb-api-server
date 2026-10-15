# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(HtmlAccessibilityEnforcer) do
  describe '.process' do
    it 'returns html unchanged when no _blank links present' do
      html = '<p>Hello <a href="http://example.com">world</a></p>'
      expect(described_class.process(html)).to(include('href="http://example.com"'))
      expect(described_class.process(html)).not_to(include('noopener'))
    end

    it 'returns nil/blank input unchanged' do
      expect(described_class.process(nil)).to(be_nil)
      expect(described_class.process('')).to(eq(''))
    end

    it 'adds rel="noopener noreferrer" to _blank links' do
      html = '<a href="http://example.com" target="_blank">click</a>'
      result = described_class.process(html)
      expect(result).to(include('noopener'))
      expect(result).to(include('noreferrer'))
    end

    it 'preserves existing rel values and adds noopener/noreferrer' do
      html = '<a href="http://example.com" target="_blank" rel="nofollow">click</a>'
      result = described_class.process(html)
      expect(result).to(include('nofollow'))
      expect(result).to(include('noopener'))
      expect(result).to(include('noreferrer'))
    end

    it 'adds aria-label with "(opens in a new tab)" when missing' do
      html = '<a href="http://example.com" target="_blank">click here</a>'
      result = described_class.process(html)
      expect(result).to(include('aria-label="click here (opens in a new tab)"'))
    end

    it 'does not overwrite existing aria-label' do
      html = '<a href="http://example.com" target="_blank" aria-label="custom label">click</a>'
      result = described_class.process(html)
      expect(result).to(include('aria-label="custom label"'))
      expect(result).not_to(include('opens in a new tab'))
    end

    it 'processes multiple _blank links' do
      html = '<a href="http://a.com" target="_blank">A</a> <a href="http://b.com" target="_blank">B</a>'
      result = described_class.process(html)
      expect(result.scan('noopener').count).to(eq(2))
    end
  end
end
