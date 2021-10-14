# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TourSet, type: :model do
  it { should validate_presence_of(:name) }

  it 'creates four travel modes' do
    tour_set = create(:tour_set)
    Apartment::Tenant.switch! tour_set.subdir
    expect(Mode.count).to eq(4)
  end

  it 'attaches logo' do
    tour_set = create(:tour_set)
    expect(tour_set.logo.attached?).to be false
    tour_set.update(
      logo_title: Faker::File.file_name(dir: '', ext: 'png', directory_separator: ''),
      base_sixty_four: File.read(Rails.root.join('spec/factories/images/png_base64.txt'))
    )
    expect(tour_set.logo.attached?).to be true
  end

  it 'removes logo' do
    tour_set = create(
      :tour_set,
      logo_title: Faker::File.file_name(dir: '', ext: 'png', directory_separator: ''),
      base_sixty_four: File.read(Rails.root.join('spec/factories/images/png_base64.txt'))
    )
    tour_set.save
    expect(tour_set.logo.attached?).to be true
    tour_set.update(base_sixty_four: nil)
    expect(tour_set.logo.attached?).to be false
  end
end
