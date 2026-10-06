# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Tour) do
  describe '.search_import' do
    let(:tour_set) { create(:tour_set) }

    before { Apartment::Tenant.switch!(tour_set.subdir) }

    def build_tour(stop_count)
      tour = create(:tour, published: false, map_icon: create(:map_icon))
      stop_count.times do |i|
        stop = create(:stop, map_icon: create(:map_icon))
        create(:tour_stop, tour:, stop:, position: i + 1, map_icon: create(:map_icon))
        2.times { |j| create(:stop_medium, stop:, medium: create(:medium), position: j + 1) }
      end
      2.times { |j| create(:tour_medium, tour:, medium: create(:medium), position: j + 1) }
      2.times { |j| create(:tour_flat_page, tour:, flat_page: create(:flat_page), position: j + 1) }
      create(:map_overlay, tour:)
      tour
    end

    def queries_for_search_data(tour)
      loaded = described_class.search_import.find(tour.id)
      count = 0
      counter = lambda do |*, payload|
        count += 1 unless payload[:name] == 'SCHEMA' || payload[:cached]
      end
      ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') { loaded.search_data }
      count
    end

    it 'builds search_data without per-stop queries' do
      small = queries_for_search_data(build_tour(2))
      large = queries_for_search_data(build_tour(10))
      expect(large).to(eq(small))
    end

    it 'produces the same search_data as a tour loaded without preloading' do
      tour = build_tour(3)
      preloaded = described_class.search_import.find(tour.id).search_data
      plain = described_class.find(tour.id).search_data
      # Signed URLs embed a timestamp, so compare everything but the URLs.
      strip = ->(h) { JSON.parse(h.to_json.gsub(%r{https?://[^"]+}, 'URL')) }
      expect(strip.call(preloaded)).to(eq(strip.call(plain)))
    end
  end
end
