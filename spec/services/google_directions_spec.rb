# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(GoogleDirections) do
  let(:origin) { [33.749, -84.388] }
  let(:destinations) { [[33.750, -84.389], [33.751, -84.390]] }
  let(:stops_count) { 2 }

  describe '#duration' do
    it 'returns summed duration plus stop overhead for BICYCLING' do
      directions = described_class.new(origin, destinations, stops_count, 'BICYCLING')
      expect(directions.duration).to(eq(5536))
    end

    it 'returns nil when Google returns INVALID_REQUEST (DRIVING)' do
      directions = described_class.new(origin, destinations, stops_count, 'DRIVING')
      expect(directions.duration).to(be_nil)
    end

    it 'returns nil when Google returns ZERO_RESULTS (WALKING)' do
      directions = described_class.new(origin, destinations, stops_count, 'WALKING')
      expect(directions.duration).to(be_nil)
    end
  end

  describe '#matrix' do
    it 'returns nil when status is not OK' do
      directions = described_class.new(origin, destinations, stops_count, 'DRIVING')
      expect(directions.matrix).to(be_nil)
    end
  end
end
