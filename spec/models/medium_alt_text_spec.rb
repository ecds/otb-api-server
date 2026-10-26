# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Medium) do
  describe 'alt text' do
    it 'is missing until it is written or the image is marked decorative' do
      medium = build(:medium)
      expect(medium.missing_alt_text?).to(be(true))
      medium.alt_text = 'The white clapboard church from the road'
      expect(medium.missing_alt_text?).to(be(false))
      expect(build(:medium, alt_text: '  ', decorative: true).missing_alt_text?).to(be(false))
    end

    it 'treats blank alt text as missing' do
      expect(build(:medium, alt_text: '   ').missing_alt_text?).to(be(true))
    end

    it 'treats alt text of fewer than three words as missing' do
      expect(build(:medium, alt_text: ' x ').missing_alt_text?).to(be(true))
      expect(build(:medium, alt_text: 'Church  front').missing_alt_text?).to(be(true))
      expect(build(:medium, alt_text: 'The church front').missing_alt_text?).to(be(false))
    end

    it 'finds the same media in the database' do
      missing = [create(:medium, alt_text: nil), create(:medium, alt_text: ' Church  front ')]
      create(:medium, alt_text: "The church\nfront")
      create(:medium, alt_text: 'x', decorative: true)
      expect(described_class.missing_alt_text).to(match_array(missing))
    end

    it 'is part of the medium data' do
      data = create(:medium, alt_text: 'Rows of pews', decorative: false).search_data
      expect(data).to(include(alt_text: 'Rows of pews', decorative: false, missing_alt_text: false))
    end
  end
end
