# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(FlatPage, type: :model) do
  it { is_expected.to(have_many(:tour_flat_pages)) }
  it { is_expected.to(have_many(:tours)) }
  it { is_expected.to(validate_presence_of(:title)) }

  describe '#slug' do
    it 'returns parameterized title' do
      flat_page = build(:flat_page, title: 'Hello World')
      expect(flat_page.slug).to(eq('hello-world'))
    end
  end

  describe '#orphaned' do
    it 'is true when not associated with any tour' do
      flat_page = create(:flat_page)
      expect(flat_page.orphaned).to(be(true))
    end

    it 'is false when associated with a tour' do
      tour = create(:tour)
      flat_page = create(:flat_page, tours: [tour])
      expect(flat_page.orphaned).to(be(false))
    end
  end

  describe '#published' do
    it 'is false when not associated with any tour' do
      flat_page = create(:flat_page)
      expect(flat_page.published).to(be(false))
    end

    it 'is false when associated only with unpublished tours' do
      tour = create(:tour, published: false)
      flat_page = create(:flat_page, tours: [tour])
      expect(flat_page.published).to(be(false))
    end

    it 'is true when associated with a published tour' do
      tour = create(:tour, published: true)
      flat_page = create(:flat_page, tours: [tour])
      expect(flat_page.published).to(be(true))
    end
  end

  describe '#search_data' do
    it 'includes expected keys' do
      flat_page = create(:flat_page)
      data = flat_page.search_data
      expect(data).to(include(:id, :title, :slug, :body, :orphaned, :tour_count))
    end
  end
end
