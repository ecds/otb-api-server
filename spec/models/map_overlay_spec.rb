require 'rails_helper'

RSpec.describe MapOverlay, type: :model do
  it 'has nil values for south, east, north, and west' do
    mo = create(:map_overlay, tour: create(:tour, stops: []))
    expect([mo.south, mo.east, mo.north, mo.west]).to all(be nil)
  end

  it 'has values for south, east, north, and west based on tour stops' do
    tour = create(:tour, stops: create_list(:stop, 3))
    mo = create(:map_overlay, tour: tour)
    expect([mo.south, mo.east, mo.north, mo.west]).to all(be_a BigDecimal)
  end
end
