# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Medium) do
  let(:tour_set) { create(:tour_set) }

  before { Apartment::Tenant.switch!(tour_set.subdir) }

  describe '#store_lqip_data!' do
    it 'stores the lqip variant as a small data URI' do
      medium = create(:medium)
      medium.store_lqip_data!
      expect(medium.reload.lqip_data).to(start_with('data:image/'))
      expect(medium.lqip_data).to(include(';base64,'))
      expect(medium.lqip_data.bytesize).to(be < 2000)
    end

    it 'skips gifs' do
      medium = create(:medium, base_sixty_four: File.read(Rails.root.join('spec/factories/images/gif_base64.txt')))
      medium.store_lqip_data!
      expect(medium.reload.lqip_data).to(be_nil)
    end
  end

  it 'is filled in by the variants job' do
    medium = create(:medium)
    ProcessMediumVariantsJob.perform_now(tenant: tour_set.subdir, id: medium.id)
    expect(medium.reload.lqip_data).to(start_with('data:image/'))
  end

  describe 'in tour and stop search data' do
    let(:tour) { create(:tour, published: false) }

    def with_lqip(medium)
      medium.update!(lqip_data: "data:image/jpeg;base64,#{medium.id}")
      medium
    end

    it 'is only included for the first tour medium by position' do
      first, second = Array.new(2) { with_lqip(create(:medium)) }
      # Created out of order; after_create assigns positions, so set them after.
      create(:tour_medium, tour:, medium: second).update!(position: 2)
      create(:tour_medium, tour:, medium: first).update!(position: 1)
      media = tour.reload.search_data[:media]
      expect(media.map { |m| m[:id] }).to(eq([first.id, second.id]))
      expect(media.first[:lqip_data]).to(eq(first.lqip_data))
      expect(media.second).not_to(have_key(:lqip_data))
    end

    it "is only included for a stop's first medium" do
      stop = create(:stop)
      first, second = Array.new(2) { with_lqip(create(:medium)) }
      create(:stop_medium, stop:, medium: first, position: 1)
      create(:stop_medium, stop:, medium: second, position: 2)
      media = stop.reload.search_data[:media]
      expect(media.first[:lqip_data]).to(eq(first.lqip_data))
      expect(media.second).not_to(have_key(:lqip_data))
    end

    it 'leaves the key out when the first medium has no lqip yet' do
      create(:tour_medium, tour:, medium: create(:medium), position: 1)
      expect(tour.reload.search_data[:media].first).not_to(have_key(:lqip_data))
    end
  end

  describe 'reindexing tours that show the medium' do
    include ActiveJob::TestHelper

    let(:medium) { create(:medium) }
    let(:direct_tour) { create(:tour, published: false) }
    let(:stop_tour) { create(:tour, published: false) }
    let(:unrelated_tour) { create(:tour, published: false) }

    before do
      create(:tour_medium, tour: direct_tour, medium:)
      stop = create(:stop)
      create(:stop_medium, stop:, medium:)
      create(:tour_stop, tour: stop_tour, stop:, position: 1)
      unrelated_tour
      clear_enqueued_jobs
    end

    def reindexed_tour_ids
      enqueued_jobs
        .select { |job| job['job_class'] == 'ReindexJob' }
        .map { |job| job['arguments'].first }
        .select { |args| args['class_name'] == 'Tour' }
        .map { |args| args['id'] }
    end

    it 'finds tours using it directly or through a stop' do
      expect(medium.tours_using).to(contain_exactly(direct_tour, stop_tour))
    end

    it 'queues a tour reindex in the current tenant when lqip_data is stored' do
      medium.store_lqip_data!
      expect(reindexed_tour_ids).to(contain_exactly(direct_tour.id, stop_tour.id))
      tenants = enqueued_jobs.select { |job| job['job_class'] == 'ReindexJob' }.map { |job| job['arguments'].first['tenant'] }
      expect(tenants.uniq).to(eq([tour_set.subdir]))
    end

    it 'queues nothing when lqip_data is unchanged' do
      medium.store_lqip_data!
      clear_enqueued_jobs
      medium.reload.store_lqip_data!
      expect(reindexed_tour_ids).to(be_empty)
    end
  end
end
