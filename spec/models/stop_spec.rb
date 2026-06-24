# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Stop, type: :model) do
  it { is_expected.to(have_many(:tours)) }
  it { is_expected.to(have_many(:tour_stops)) }
  # it { should validate_presence_of(:title) }
  it { is_expected.to(have_many(:stop_media)) }
  it { is_expected.to(have_many(:media)) }

  it 'has specified splash' do
    stop = create(:stop, medium: create(:medium))
    expect(stop.splash).not_to(be_nil)
  end

  it 'has uses the first medium for splash' do
    stop = create(:stop)
    create_list(:medium, 3)
    Medium.all.find_each { |medium| stop.media << medium }
    expect(stop.splash).not_to(be_nil)
    expect(stop.splash[:title]).to(eq(StopMedium.find_by(position: 1).medium.title))
  end

  it 'does not allow a title with a duplicate name' do
    title = Faker::Movies::HitchhikersGuideToTheGalaxy.location
    create(:stop, title:)
    expect(build(:stop, title:)).not_to(be_valid)
  end

  context 'when html field contains _blank link with no rel or aria-label' do
    it 'adds rel="noopener noreferrer" to link.' do
      description = 'click <a href="http://example.org" target="_blank">here</a>'
      stop = create(:stop, description:)
      expect(stop.description).to(include('rel="noopener noreferrer"'))
    end

    it 'adds aria-label="here (opens in a new tab)" to link.' do
      description = 'click <a href="http://example.org" target="_blank">here</a>'
      stop = create(:stop, description:)
      expect(stop.description).to(include('aria-label="here (opens in a new tab)"'))
    end

    it 'adds rel="noopener noreferrer" to link in direction notes.' do
      direction_notes = 'click <a href="http://example.org" target="_blank">here</a>'
      stop = create(:stop, direction_notes:)
      expect(stop.direction_notes).to(include('rel="noopener noreferrer"'))
    end

    it 'adds aria-label="here (opens in a new tab)" to link in direction notes.' do
      direction_notes = 'click <a href="http://example.org" target="_blank">here</a>'
      stop = create(:stop, direction_notes:)
      expect(stop.direction_notes).to(include('aria-label="here (opens in a new tab)"'))
    end
  end
end
