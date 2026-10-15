# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(ReindexService) do
  let(:tour_set) { create(:tour_set) }
  let(:reindexed) { [] }

  before do
    Apartment::Tenant.switch!(tour_set.subdir)
    log = reindexed
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(Tour).to(receive(:reindex) { |tour| log << tour })
    # rubocop:enable RSpec/AnyInstance
  end

  def preloaded?(tour)
    [:tour_stops, :tour_media, :theme].all? { |name| tour.association(name).loaded? }
  end

  it 'reindexes a tour from a fully preloaded copy' do
    tour = create(:tour, published: false)
    described_class.call(Tour.find(tour.id))
    expect(reindexed.map(&:id)).to(eq([tour.id]))
    expect(reindexed.all? { |t| preloaded?(t) }).to(be(true))
  end

  it 'reindexes the tours of a join record from preloaded copies' do
    tour = create(:tour, published: false)
    join = create(:tour_stop, tour:, stop: create(:stop), position: 1)
    described_class.call(TourStop.find(join.id))
    expect(reindexed.map(&:id)).to(include(tour.id))
    expect(reindexed.all? { |t| preloaded?(t) }).to(be(true))
  end

  it 'leaves models without a search_import scope as they are' do
    stop = create(:stop)
    expect(described_class.preloaded(stop)).to(equal(stop))
  end
end
