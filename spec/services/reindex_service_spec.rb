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

  describe '.enqueue' do
    include ActiveJob::TestHelper

    def queued_reindexes
      enqueued_jobs.select { |job| job[:job] == ReindexJob }.map { |job| job[:args].first.slice('class_name', 'id') }
    end

    before { clear_enqueued_jobs }

    it "queues a join record's tours instead of rebuilding them in the request" do
      tour = create(:tour, published: false)
      join = create(:tour_stop, tour:, stop: create(:stop), position: 1)
      clear_enqueued_jobs
      described_class.enqueue(join)
      expect(queued_reindexes).to(eq([{ 'class_name' => 'TourStop', 'id' => join.id }]))
      expect(reindexed).to(be_empty)
    end

    it 'adds nothing for a searchable record, which queues its own job' do
      tour = create(:tour, published: false)
      clear_enqueued_jobs
      described_class.enqueue(tour)
      expect(queued_reindexes).to(be_empty)
    end

    it "queues the tours of a deleted join, which a job couldn't look up later" do
      tour = create(:tour, published: false)
      join = create(:tour_stop, tour:, stop: create(:stop), position: 1)
      join.destroy!
      clear_enqueued_jobs
      described_class.enqueue(join)
      expect(queued_reindexes).to(eq([{ 'class_name' => 'Tour', 'id' => tour.id }]))
    end
  end
end
