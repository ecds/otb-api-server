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
    tour = create(:tour, mode: Mode.find_by(title: 'BICYCLING'), stops: create_list(:stop, 3))
    expect(tour.duration).to eq(6136)
  end

  it 'gets no duration whin invalid request is made to Google' do
    tour = create(:tour, mode: Mode.find_by(title: 'DRIVING'), stops: create_list(:stop, 5))
    expect(tour.duration).to be nil
  end

  it 'gets no duration whin response has ZERO_RESULTS' do
    tour = create(:tour, mode: Mode.find_by(title: 'WALKING'), stops: create_list(:stop, 4))
    expect(tour.duration).to be nil
  end
end
