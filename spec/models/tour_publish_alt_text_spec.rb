# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Tour) do
  describe 'publishing with images missing alt text' do
    let(:tour) { create(:tour, published: false) }

    def add_tour_medium(**attrs)
      create(:tour_medium, tour:, medium: create(:medium, **attrs))
    end

    def add_stop_medium(**attrs)
      stop = create(:stop)
      create(:tour_stop, tour:, stop:)
      create(:stop_medium, stop:, medium: create(:medium, **attrs))
    end

    it 'is refused while an image has no alt text' do
      add_tour_medium(alt_text: nil)
      expect(tour.update(published: true)).to(be(false))
      expect(tour.errors[:published].first).to(include('1 image needs it'))
      expect(tour.reload.published).to(be(false))
    end

    it "counts the stops' images too, and embeds" do
      add_stop_medium(alt_text: nil)
      add_tour_medium(alt_text: '', embed: '//www.youtube.com/embed/x')
      tour.update(published: true)
      expect(tour.errors[:published].first).to(include('2 images need it'))
    end

    it 'is allowed once every image has alt text or is decorative' do
      add_tour_medium(alt_text: 'The church from the road')
      add_stop_medium(alt_text: nil, decorative: true)
      expect(tour.update(published: true)).to(be(true))
    end

    it 'leaves tours that are already published alone' do
      published = create(:tour, published: true)
      create(:tour_medium, tour: published, medium: create(:medium, alt_text: nil))
      expect(published.update(title: 'Renamed')).to(be(true))
      expect(published.reload.published).to(be(true))
    end

    it 'can still be unpublished' do
      published = create(:tour, published: true)
      create(:tour_medium, tour: published, medium: create(:medium, alt_text: nil))
      expect(published.update(published: false)).to(be(true))
    end
  end
end
