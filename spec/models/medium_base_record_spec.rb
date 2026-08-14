# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(MediumBaseRecord, type: :model) do
  describe 'JPEG 2000 rejection' do
    it 'is invalid when base64 content type is JPEG 2000' do
      jp2_base64 = "data:image/jp2;base64,#{Base64.encode64('fake jp2 data')}"
      medium = build(:medium, base_sixty_four: jp2_base64, filename: 'test.jp2')
      expect(medium).not_to(be_valid)
      expect(medium.errors[:base]).to(include(match(/JPEG 2000/)))
    end

    it 'is valid for standard jpeg content' do
      medium = build(:medium)
      expect(medium).to(be_valid)
    end
  end
end
