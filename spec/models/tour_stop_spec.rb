# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(TourStop, type: :model) do
  it { is_expected.to(belong_to(:tour)) }
  it { is_expected.to(belong_to(:stop)) }
  it { is_expected.to(belong_to(:map_icon).optional) }

  describe 'map icon' do
    let(:tour_set) { create(:tour_set) }
    let(:tour) { create(:tour, published: false) }
    let(:tour_stop) { create(:tour_stop, tour:, stop: create(:stop), position: 1) }

    before { Apartment::Tenant.switch!(tour_set.subdir) }

    it 'has no icon when neither the stop nor the tour has one' do
      expect(tour_stop.search_data).to(include(map_icon: nil, map_icon_custom: false))
    end

    it "falls back to the tour's icon" do
      tour.update!(map_icon: create(:map_icon))
      tour_stop.reload
      expect(tour_stop.effective_map_icon).to(eq(tour.map_icon))
      expect(tour_stop.search_data[:map_icon]).to(be_present)
      expect(tour_stop.search_data[:map_icon_custom]).to(be(false))
    end

    it "uses its own icon over the tour's" do
      tour.update!(map_icon: create(:map_icon))
      own = create(:map_icon)
      tour_stop.update!(map_icon: own)
      expect(tour_stop.effective_map_icon).to(eq(own))
      expect(tour_stop.search_data[:map_icon_custom]).to(be(true))
    end

    it "overrides the stop's own icon field" do
      tour_stop.stop.update!(map_icon: create(:map_icon))
      expect(tour_stop.reload.search_data[:map_icon]).to(be_nil)
    end

    it 'is per tour: the same stop can have different icons in different tours' do
      other_tour = create(:tour, published: false)
      other = create(:tour_stop, tour: other_tour, stop: tour_stop.stop, position: 1)
      tour_stop.update!(map_icon: create(:map_icon))
      expect(other.reload.search_data[:map_icon]).to(be_nil)
    end

    it 'detaches when the icon is deleted' do
      icon = create(:map_icon)
      tour_stop.update!(map_icon: icon)
      icon.destroy!
      expect(tour_stop.reload.map_icon_id).to(be_nil)
    end
  end
end
