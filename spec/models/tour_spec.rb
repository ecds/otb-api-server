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
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), stops: create_list(:stop, 3), published: true)
    tour.save
    expect(tour.duration).to eq(6136)
  end

  it 'gets no duration when unpublished' do
    tour = create(:tour, mode: Mode.find_by(title: 'TRANSIT'), stops: create_list(:stop, 3), published: false)
    tour.save
    expect(tour.duration).to be nil
  end

  it 'gets duration when tour is updated to published' do
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), stops: create_list(:stop, 3), published: false)
    expect(tour.duration).to be nil
    tour.update(published: true)
    expect(tour.saved_change_to_attribute?(:published)).to be true
    expect(tour.duration).to eq(6136)
  end

  it 'updates duration when mode changes' do
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), stops: create_list(:stop, 3), published: true)
    tour.save
    expect(tour.duration).to eq(6136)
    tour.mode = Mode.find_by(title: 'TRANSIT')
    expect(tour.will_save_change_to_mode_id?).to be true
    tour.save
    expect(tour.duration).to eq(5136)
    expect(tour.saved_change_to_attribute?(:duration)).to be true
  end

  it 'updates duration when stop order chages' do
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), published: true)
    3.times { |i| create(:tour_stop, tour: tour, stop: create(:stop), position: i + 1) }
    tour.save
    expect(tour.duration).to eq(6136)
    # Trick the network stub to fetch different distance matrix but doesn't presist a
    # change to the tour's mode.
    tour.mode.title = 'TRANSIT'
    tour.tour_stops.order(:position).last.update(position: 0)
    tour.validate
    # Make sure duration isn't being updated because we changed the mode's title.
    expect(tour.will_save_change_to_mode_id?).to be false
    expect(tour.will_save_change_to_saved_stop_order?).to be true
    tour.save
    expect(tour.saved_change_to_attribute?(:saved_stop_order)).to be true
    expect(tour.duration).to eq(5136)
    expect(tour.saved_change_to_attribute?(:duration)).to be true
  end

  it 'gets no duration whin invalid request is made to Google' do
    tour = create(:tour, mode: Mode.find_by(title: 'DRIVING'), stops: create_list(:stop, 5), published: true)
    tour.save
    expect(tour.duration).to be nil
  end

  it 'gets no duration whin response has ZERO_RESULTS' do
    tour = create(:tour, mode: Mode.find_by(title: 'WALKING'), stops: create_list(:stop, 4), published: true)
    tour.save
    expect(tour.duration).to be nil
  end

  it 'does not update the duration when other attributes are updaeted' do
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), stops: create_list(:stop, 3), published: true)
    tour.save
    expect(tour.duration).to eq(6136)
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
    expect(tour.duration).to eq(6136)
  end
end
