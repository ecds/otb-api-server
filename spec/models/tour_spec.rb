# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tour, type: :model do
  # it { should validate_presence_of(:title) }
  # it { expect(subject).to validate_presence_of :title }
  it { expect(subject).to have_many(:stops) }
  it { expect(subject).to have_many(:tour_stops) }
  it { expect(Tour.reflect_on_association(:theme).macro).to eq(:belongs_to) }
  it { expect(Tour.reflect_on_association(:mode).macro).to eq(:belongs_to) }

  it 'gets a duration' do
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), stops: create_list(:stop, 5), published: false)
    tour.update(published: true)
    tour.save
    expect(tour.duration).to eq(7336)
  end

  it 'gets no duration when unpublished' do
    tour = create(:tour, mode: Mode.find_by(title: 'TRANSIT'), stops: create_list(:stop, 5), published: false)
    tour.update(published: false)
    tour.save
    expect(tour.duration).to be nil
  end

  it 'gets duration when tour is updated to published' do
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), stops: create_list(:stop, 5), published: false)
    tour.update(published: false)
    expect(tour.duration).to be nil
    tour.update(published: true)
    expect(tour.saved_change_to_attribute?(:published)).to be true
    expect(tour.duration).to eq(7336)
  end

  it 'updates duration when mode changes' do
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), stops: create_list(:stop, 5), published: false)
    tour.update(published: true)
    tour.save
    expect(tour.duration).to eq(7336)
    tour.mode = Mode.find_by(title: 'TRANSIT')
    expect(tour.will_save_change_to_mode_id?).to be true
    tour.save
    expect(tour.duration).to eq(6336)
    expect(tour.saved_change_to_attribute?(:duration)).to be true
    expect(tour.saved_change_to_attribute?(:saved_stop_order)).to be false
  end

  it 'updates duration when stop order chages' do
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), published: false)
    5.times { |i| create(:tour_stop, tour: tour, stop: create(:stop), position: i + 1) }
    tour.update(published: true)
    tour.save
    expect(tour.duration).to eq(7336)
    # Trick the network stub to fetch different distance matrix but doesn't presist a
    # change to the tour's mode.
    tour.mode.title = 'TRANSIT'
    tour.tour_stops.order(:position).last.update(position: 0)
    tour.validate
    # Make sure duration isn't being updated because we changed the mode or published status.
    expect(tour.will_save_change_to_mode_id?).to be false
    expect(tour.will_save_change_to_published?).to be false
    expect(tour.will_save_change_to_saved_stop_order?).to be true
    tour.save
    expect(tour.duration).to eq(6336)
    expect(tour.saved_change_to_attribute?(:duration)).to be true
  end

  it 'gets no duration whin invalid request is made to Google' do
    tour = create(:tour, mode: Mode.find_by(title: 'DRIVING'), stops: create_list(:stop, 5), published: false)
    tour.update(published: true)
    tour.save
    expect(tour.duration).to be nil
  end

  it 'gets no duration whin response has ZERO_RESULTS' do
    tour = create(:tour, mode: Mode.find_by(title: 'WALKING'), stops: create_list(:stop, 4), published: false)
    tour.update(published: true)
    tour.save
    expect(tour.duration).to be nil
  end

  it 'does not update the duration when other attributes are updaeted' do
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), stops: create_list(:stop, 5), published: false)
    tour.update(published: true)
    tour.save
    expect(tour.duration).to eq(7336)
    # Trick the network stub to fetch different distance matrix but doesn't presist a
    # change to the tour's mode. In this case, it should NOT fetch. This is just to
    # test that it does not actually make teh request when we don't want it to.
    tour.mode.title = 'TRANSIT'
    tour.update(
      title: Faker::Music::Prince.band,
      description: Faker::Music::Prince.lyric
    )
    expect(tour.saved_change_to_attribute?(:title)).to be true
    expect(tour.saved_change_to_attribute?(:description)).to be true
    expect(tour.saved_change_to_attribute?(:duration)).to be false
    expect(tour.saved_change_to_attribute?(:published)).to be false
    expect(tour.saved_change_to_attribute?(:saved_stop_order)).to be false
    expect(tour.duration).to eq(7336)
  end

  it 'when restricted to overlay bounds, tour bounds mirror overlay' do
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), stops: create_list(:stop, 5), published: false)
    mo = create(:map_overlay, tour: tour)
    mo.update(
      south: '33.73324867399921',
      north: '33.81498938289962',
      east: '-84.25453244903566',
      west: '-84.37135369046021'
    )
    tour.update(restrict_bounds_to_overlay: true)
    expect(tour.bounds[:south]).to eq(33.723031085386665)
  end

  it 'has no bounds when no stops' do
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), published: false)
    expect(tour.bounds).to be nil
  end

  it 'does not restrict bounds to overlay when no overlay' do
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), stops: create_list(:stop, 5), restrict_bounds_to_overlay: true)
    expect(tour.restrict_bounds_to_overlay).to be false
  end

  it 'sets restrict_bounds to false when restricted to overlay bounds' do
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), stops: create_list(:stop, 5), restrict_bounds_to_overlay: true)
    mo = create(:map_overlay, tour: tour)
    expect(tour.restrict_bounds).to be true
    tour.update(restrict_bounds_to_overlay: true)
    expect(tour.restrict_bounds).to be false
    expect(tour.restrict_bounds_to_overlay).to be true
  end

  it 'sets restrict_to_overlay_bounds when updated to restrict_bounds' do
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), stops: create_list(:stop, 5), restrict_bounds_to_overlay: true)
    mo = create(:map_overlay, tour: tour)
    expect(tour.restrict_bounds).to be true
    tour.update(restrict_bounds_to_overlay: true)
    expect(tour.restrict_bounds).to be false
    expect(tour.restrict_bounds_to_overlay).to be true
    tour.update(restrict_bounds: true)
    expect(tour.restrict_bounds).to be true
    expect(tour.restrict_bounds_to_overlay).to be false
  end

  it 'allows both restrictions to be false' do
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), stops: create_list(:stop, 5))
    mo = create(:map_overlay, tour: tour)
    expect(tour.restrict_bounds).to be true
    tour.update(restrict_bounds: false)
    expect(tour.restrict_bounds).to be false
    expect(tour.restrict_bounds_to_overlay).to be false
  end

  it 'will not allow restriction to overlay if no overlay' do
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), stops: create_list(:stop, 5))
    tour.update(restrict_bounds_to_overlay: true)
    expect(tour.restrict_bounds_to_overlay).to be false
  end
end
