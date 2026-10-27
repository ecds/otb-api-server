# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(GoogleDirections) do
  let(:origin) { [33.749, -84.388] }
  let(:destinations) { [[33.750, -84.389], [33.751, -84.390]] }
  let(:stops_count) { 2 }

  describe '#duration' do
    it 'returns summed duration plus stop overhead for BICYCLING' do
      directions = described_class.new(origin, destinations, stops_count, 'bicycling')
      expect(directions.duration).to(eq(5536))
    end

    it 'returns nil when Google returns INVALID_REQUEST (DRIVING)' do
      directions = described_class.new(origin, destinations, stops_count, 'driving')
      expect(directions.duration).to(be_nil)
    end

    it 'returns nil when Google returns ZERO_RESULTS (WALKING)' do
      directions = described_class.new(origin, destinations, stops_count, 'walking')
      expect(directions.duration).to(be_nil)
    end
  end

  describe '#matrix' do
    it 'returns nil when status is not OK' do
      directions = described_class.new(origin, destinations, stops_count, 'driving')
      expect(directions.matrix).to(be_nil)
    end
  end

  describe '#leg' do
    it 'gives the time when Google has a route' do
      leg = described_class.new(origin, destinations, stops_count, 'bicycling').leg
      expect(leg.seconds).to(be_positive)
      expect(leg.problem).to(be_nil)
    end

    it 'says there is no route for ZERO_RESULTS' do
      leg = described_class.new(origin, destinations, stops_count, 'walking').leg
      expect(leg.problem).to(eq(:no_route))
    end

    it 'says Google turned it down, and why' do
      leg = described_class.new(origin, destinations, stops_count, 'driving').leg
      expect([leg.problem, leg.status]).to(eq([:refused, 'INVALID_REQUEST']))
    end

    it "says Google couldn't be reached on a timeout or a non-JSON answer" do
      stub_request(:get, /bicycling/).to_timeout
      expect(described_class.new(origin, destinations, stops_count, 'bicycling').leg.problem).to(eq(:unreachable))
      stub_request(:get, /bicycling/).to_return(status: 502, body: '<html>Bad gateway</html>', headers: { 'Content-Type' => 'text/html' })
      expect(described_class.new(origin, destinations, stops_count, 'bicycling').leg.problem).to(eq(:unreachable))
    end
  end
end
