# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TourSet, type: :model do
  it { should validate_presence_of(:name) }

  it 'creates four travel modes' do
    tour_set = create(:tour_set)
    Apartment::Tenant.switch! tour_set.subdir
    expect(Mode.count).to eq(4)
  end
end
