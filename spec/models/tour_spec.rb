# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Tour, type: :model) do
  # it { should validate_presence_of(:title) }
  # it { expect(subject).to validate_presence_of :title }
  it { expect(subject).to(have_many(:stops)) }
  it { expect(subject).to(have_many(:tour_stops)) }
  it { expect(described_class.reflect_on_association(:theme).macro).to(eq(:belongs_to)) }
  it { expect(described_class.reflect_on_association(:mode).macro).to(eq(:belongs_to)) }

  it 'gets a duration' do
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), stops: create_list(:stop, 5), published: false)
    tour.update(published: true)
    tour.save
    expect(tour.duration).to(eq(7336))
  end

  it 'gets no duration when unpublished' do
    tour = create(:tour, mode: Mode.find_by(title: 'TRANSIT'), stops: create_list(:stop, 5), published: false)
    tour.update(published: false)
    tour.save
    expect(tour.duration).to(be_nil)
  end

  it 'gets duration when tour is updated to published' do
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), stops: create_list(:stop, 5), published: false)
    tour.update(published: false)
    expect(tour.duration).to(be_nil)
    tour.update(published: true)
    expect(tour.saved_change_to_attribute?(:published)).to(be(true))
    expect(tour.duration).to(eq(7336))
  end

  it 'updates duration when mode changes' do
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), stops: create_list(:stop, 5), published: false)
    tour.update(published: true)
    tour.save
    expect(tour.duration).to(eq(7336))
    tour.mode = Mode.find_by(title: 'TRANSIT')
    expect(tour.will_save_change_to_mode_id?).to(be(true))
    tour.save
    expect(tour.duration).to(eq(6336))
    expect(tour.saved_change_to_attribute?(:duration)).to(be(true))
    expect(tour.saved_change_to_attribute?(:saved_stop_order)).to(be(false))
  end

  it 'updates duration when stop order changes' do
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), published: false)
    5.times { |i| create(:tour_stop, tour: tour, stop: create(:stop), position: i + 1) }
    tour.update(published: true)
    tour.save
    expect(tour.duration).to(eq(7336))
    # Trick the network stub to fetch different distance matrix but doesn't persist a
    # change to the tour's mode.
    tour.mode.title = 'TRANSIT'
    tour.tour_stops.order(:position).last.update(position: 0)
    tour.validate
    # Make sure duration isn't being updated because we changed the mode or published status.
    expect(tour.will_save_change_to_mode_id?).to(be(false))
    expect(tour.will_save_change_to_published?).to(be(false))
    expect(tour.will_save_change_to_saved_stop_order?).to(be(true))
    tour.save
    expect(tour.duration).to(eq(6336))
    expect(tour.saved_change_to_attribute?(:duration)).to(be(true))
  end

  it 'gets no duration whin invalid request is made to Google' do
    tour = create(:tour, mode: Mode.find_by(title: 'DRIVING'), stops: create_list(:stop, 5), published: false)
    tour.update(published: true)
    tour.save
    expect(tour.duration).to(be_nil)
  end

  it 'gets no duration whin response has ZERO_RESULTS' do
    tour = create(:tour, mode: Mode.find_by(title: 'WALKING'), stops: create_list(:stop, 4), published: false)
    tour.update(published: true)
    tour.save
    expect(tour.duration).to(be_nil)
  end

  it 'does not update the duration when other attributes are updaeted' do
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), stops: create_list(:stop, 5), published: false)
    tour.update(published: true)
    tour.save
    expect(tour.duration).to(eq(7336))
    # Trick the network stub to fetch different distance matrix but doesn't presist a
    # change to the tour's mode. In this case, it should NOT fetch. This is just to
    # test that it does not actually make teh request when we don't want it to.
    tour.mode.title = 'TRANSIT'
    tour.update(
      title: Faker::Music::Prince.band,
      description: Faker::Music::Prince.lyric,
    )
    expect(tour.saved_change_to_attribute?(:title)).to(be(true))
    expect(tour.saved_change_to_attribute?(:description)).to(be(true))
    expect(tour.saved_change_to_attribute?(:duration)).to(be(false))
    expect(tour.saved_change_to_attribute?(:published)).to(be(false))
    expect(tour.saved_change_to_attribute?(:saved_stop_order)).to(be(false))
    expect(tour.duration).to(eq(7336))
  end

  it 'when restricted to overlay bounds, tour bounds mirror overlay' do
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), stops: create_list(:stop, 5), published: false)
    mo = create(:map_overlay, tour: tour)
    mo.update(
      south: '33.73324867399921',
      north: '33.81498938289962',
      east: '-84.25453244903566',
      west: '-84.37135369046021',
    )
    tour.update(restrict_bounds_to_overlay: true)
    expect(tour.bounds[:south]).to(eq(33.723031085386665))
  end

  it 'has no bounds when no stops' do
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), published: false)
    expect(tour.bounds).to(be_nil)
  end

  it 'does not restrict bounds to overlay when no overlay' do
    tour = create(
      :tour,
      mode: Mode.find_by(title: 'BICYCLING'),
      stops: create_list(:stop, 5),
      restrict_bounds_to_overlay: true,
    )
    expect(tour.restrict_bounds_to_overlay).to(be(false))
  end

  # it 'sets restrict_bounds to false when restricted to overlay bounds' do
  #   tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), stops: create_list(:stop, 5), restrict_bounds_to_overlay: true)
  #   expect(tour.restrict_bounds).to be true
  #   tour.update(restrict_bounds_to_overlay: true)
  #   expect(tour.restrict_bounds).to be false
  #   expect(tour.restrict_bounds_to_overlay).to be true
  # end

  # it 'sets restrict_to_overlay_bounds when updated to restrict_bounds' do
  #   tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), stops: create_list(:stop, 5), restrict_bounds_to_overlay: true)
  #   expect(tour.restrict_bounds_to_overlay).to be false
  #   create(:map_overlay, tour:)
  #   tour.update(restrict_bounds_to_overlay: true)
  #   expect(tour.restrict_bounds).to be false
  #   expect(tour.restrict_bounds_to_overlay).to be true
  #   tour.update(restrict_bounds: true)
  #   expect(tour.restrict_bounds).to be true
  #   expect(tour.restrict_bounds_to_overlay).to be false
  # end

  it 'allows both restrictions to be false' do
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), stops: create_list(:stop, 5))
    expect(tour.restrict_bounds).to(be(true))
    tour.update(restrict_bounds: false)
    expect(tour.restrict_bounds).to(be(false))
    expect(tour.restrict_bounds_to_overlay).to(be(false))
  end

  it 'does not allow restriction to overlay if no overlay' do
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), stops: create_list(:stop, 5))
    tour.update(restrict_bounds_to_overlay: true)
    expect(tour.restrict_bounds_to_overlay).to(be(false))
  end

  it 'does not allow a title with a duplicate name' do
    title = Faker::Movies::HitchhikersGuideToTheGalaxy.location
    create(:tour, title:)
    expect(build(:tour, title:)).not_to(be_valid)
  end

  it 'takes the first stop medium for splash when tour has no media' do
    tour = create(:tour, media: [], stops: [])
    stop = create(:stop_with_media, tours: [tour])
    tour.reload
    expect(tour.search_data[:splash][:url]).to(eq(stop.media.first.search_data[:files][:desktop]))
  end

  describe '#check_for_overlay' do
    subject(:tour) { build(:tour) }

    context 'when restrict_bounds_to_overlay is true but no overlay exists' do
      before do
        tour.map_overlay = nil
        tour.restrict_bounds_to_overlay = true
      end

      it 'resets restrict_bounds_to_overlay to false' do
        tour.save
        expect(tour.restrict_bounds_to_overlay).to(be(false))
      end
    end

    context 'when restrict_bounds_to_overlay is changed to true and an overlay exists' do
      before do
        tour.map_overlay = build(:map_overlay)
        tour.restrict_bounds = true
        tour.restrict_bounds_to_overlay = true
      end

      it 'disables restrict_bounds' do
        tour.save
        expect(tour.restrict_bounds).to(be(false))
      end

      it 'leaves restrict_bounds_to_overlay enabled' do
        tour.save
        expect(tour.restrict_bounds_to_overlay).to(be(true))
      end
    end

    context 'when restrict_bounds is changed to true' do
      before do
        create(:map_overlay, tour:)
        tour.update(restrict_bounds_to_overlay: true)
        tour.restrict_bounds = true
      end

      it 'disables restrict_bounds_to_overlay' do
        tour.save
        expect(tour.restrict_bounds_to_overlay).to(be(false))
      end

      it 'leaves restrict_bounds enabled' do
        tour.update(restrict_bounds: true)
        expect(tour.restrict_bounds).to(be(true))
      end
    end

    context 'when neither flag is changed' do
      before do
        tour.map_overlay = build(:map_overlay)
        tour.restrict_bounds = false
        tour.restrict_bounds_to_overlay = false
      end

      it 'does not change restrict_bounds' do
        expect { tour.save }.not_to(change(tour, :restrict_bounds))
      end

      it 'does not change restrict_bounds_to_overlay' do
        expect { tour.save }.not_to(change(tour, :restrict_bounds_to_overlay))
      end
    end
  end

  describe 'dependent associations' do
    it 'destroys tour_flat_pages join records when tour is deleted but preserves flat pages' do
      tour = create(:tour_with_flat_pages, flat_pages_count: 2)
      flat_page_ids = tour.flat_pages.pluck(:id)
      tour.reload.destroy
      expect(TourFlatPage.where(tour_id: tour.id)).to(be_empty)
      expect(FlatPage.where(id: flat_page_ids).count).to(eq(flat_page_ids.size))
    end

    it 'destroys tour_flat_pages join records when flat page is deleted but preserves tour' do
      tour = create(:tour_with_flat_pages, flat_pages_count: 1)
      flat_page = tour.flat_pages.first
      expect { flat_page.destroy }.to(change(TourFlatPage, :count).by(-1))
      expect(Tour.exists?(tour.id)).to(be(true))
    end
  end

  context 'when description contains _blank link with no rel or aria-label' do
    it 'adds rel="noopener noreferrer" to link.' do
      description = 'click <a href="http://example.org" target="_blank">here</a>'
      tour = create(:tour, description:)
      expect(tour.description).to(include('rel="noopener noreferrer"'))
    end

    it 'adds aria-label="here (opens in a new tab)" to link.' do
      description = 'click <a href="http://example.org" target="_blank">here</a>'
      tour = create(:tour, description:)
      expect(tour.description).to(include('aria-label="here (opens in a new tab)"'))
    end
  end

  context 'when the published status of a tour is changed' do
    it 'sets published_on when published' do
      tour = create(:tour, published: false)
      expect(tour.published_on).to(be_nil)
      tour.update(published: true)
      expect(tour.published_on).to(be_present)
    end

    it 'sets published_on to null when unpublished' do
      tour = create(:tour, published: true)
      expect(tour.published_on).to(be_present)
      tour.update(published: false)
      expect(tour.published_on).to(be_nil)
    end
  end
end
