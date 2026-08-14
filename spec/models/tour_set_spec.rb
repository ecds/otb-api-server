# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(TourSet, type: :model) do
  it { is_expected.to(validate_presence_of(:name)) }

  it 'creates four travel modes' do
    tour_set = create(:tour_set)
    Apartment::Tenant.switch!(tour_set.subdir)
    expect(Mode.count).to(eq(4))
  end

  it 'attaches logo' do
    tour_set = create(:tour_set)
    expect(tour_set.logo.attached?).to(be(false))
    tour_set.update(
      logo_title: Faker::File.file_name(dir: '', ext: 'png', directory_separator: ''),
      base_sixty_four: File.read(Rails.root.join('spec/factories/images/png_base64.txt')),
    )
    expect(tour_set.logo.attached?).to(be(true))
  end

  it 'removes logo' do
    tour_set = create(
      :tour_set,
      logo_title: Faker::File.file_name(dir: '', ext: 'png', directory_separator: ''),
      base_sixty_four: File.read(Rails.root.join('spec/factories/images/png_base64.txt')),
    )
    tour_set.save
    expect(tour_set.logo.attached?).to(be(true))
    tour_set.update(base_sixty_four: nil)
    expect(tour_set.logo.attached?).to(be(false))
  end

  describe 'renaming' do
    it 'renames the tenant schema and records the old subdir in history' do
      tour_set = create(:tour_set)
      old_subdir = tour_set.subdir

      tour_set.update!(name: 'A Brand New Name')

      expect(tour_set.subdir).to(eq('a-brand-new-name'))
      expect(described_class.exists?(subdir: old_subdir)).to(be(false))
      expect(tour_set.subdir_histories.pluck(:subdir)).to(include(old_subdir))

      Apartment::Tenant.switch!(tour_set.subdir)
      expect(Mode.count).to(eq(4))
      Apartment::Tenant.switch!('public')
    end

    it "rejects a rename that collides with another tenant's current subdir" do
      create(:tour_set, name: 'Bobs Site')
      tour_set = create(:tour_set)

      tour_set.name = 'BOBS SITE' # different name, same parameterized subdir
      expect(tour_set.save).to(be(false))
      expect(tour_set.errors[:subdir]).to(be_present)
    end

    it 'rejects reusing a subdir that used to belong to another tenant' do
      renamed_away = create(:tour_set)
      old_subdir = renamed_away.subdir
      renamed_away.update!(name: 'Something Else Entirely')

      tour_set = create(:tour_set)
      tour_set.name = old_subdir.titleize
      expect(tour_set.save).to(be(false))
      expect(tour_set.errors[:subdir]).to(be_present)
    end
  end
end
