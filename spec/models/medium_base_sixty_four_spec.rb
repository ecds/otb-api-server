# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Medium) do
  def stored_base_sixty_four(medium)
    Medium.where(id: medium.id).pick(:base_sixty_four)
  end

  it 'drops the Base64 copy once a V3 upload is attached' do
    medium = create(:medium)
    expect(medium.file).to(be_attached)
    expect(stored_base_sixty_four(medium)).to(be_nil)
  end

  it 'drops a Base64 copy left behind after the image was attached (e.g. video thumbnails)' do
    medium = create(:medium)
    medium.update!(base_sixty_four: File.read(Rails.root.join('spec/factories/base64_image.txt')))
    expect(stored_base_sixty_four(medium)).to(be_nil)
    expect(medium.reload.file).to(be_attached)
  end

  it 'keeps the Base64 data when there is no attached image to replace it' do
    medium = create(:medium, base_sixty_four: nil, embed_id: nil, video: nil)
    medium.update_column(:base_sixty_four, 'abc') # rubocop:disable Rails/SkipsModelValidations
    medium.update!(title: 'Renamed')
    expect(stored_base_sixty_four(medium)).to(eq('abc'))
  end
end
