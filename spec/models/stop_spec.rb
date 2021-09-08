# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Stop, type: :model do
  it { should have_many(:tours) }
  it { should have_many(:tour_stops) }
  # it { should validate_presence_of(:title) }
  it { should have_many(:stop_media) }
  it { should have_many(:media) }

  it 'has specified splash' do
    stop = create(:stop, medium: create(:medium))
    expect(stop.splash).not_to be nil
  end

  it 'has uses the first medium for splash' do
    stop = create(:stop)
    create_list(:medium, 3)
    Medium.all.each { |medium| stop.media << medium }
    expect(stop.splash).not_to be nil
    expect(stop.splash[:title]).to eq(StopMedium.find_by(position: 1).medium.title)
  end
end
