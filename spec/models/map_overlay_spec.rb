# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(MapOverlay, type: :model) do
  it 'has nil values for south, east, north, and west' do
    mo = create(:map_overlay, tour: create(:tour, stops: []))
    expect([mo.south, mo.east, mo.north, mo.west]).to(all(be_nil))
  end

  it 'has values for south, east, north, and west based on tour stops' do
    tour = create(:tour, stops: create_list(:stop, 3))
    mo = create(:map_overlay, tour: tour)
    expect([mo.south, mo.east, mo.north, mo.west]).to(all(be_a(String)))
  end

  describe 'initial bounds from the image' do
    let(:tour) { create(:tour, stops: create_list(:stop, 3)) }

    # Box size in map projection: degrees of longitude by Mercator y.
    def projected_aspect(overlay)
      y = ->(lat) { Math.log(Math.tan((Math::PI / 4) + (lat.to_f * Math::PI / 360))) * 180 / Math::PI }
      (overlay.east.to_f - overlay.west.to_f) / (y.call(overlay.north) - y.call(overlay.south))
    end

    def upload(width, height)
      path = Rails.root.join('tmp', "overlay-#{width}x#{height}.png")
      require 'vips'
      Vips::Image.black(width, height).write_to_file(path.to_s)
      Rack::Test::UploadedFile.new(path, 'image/png')
    end

    def overlay_for(width, height, **attrs)
      overlay = build(:map_overlay, tour:, base_sixty_four: nil, **attrs)
      overlay.file.attach(upload(width, height))
      overlay.save!
      overlay
    end

    def within_tour?(overlay)
      bounds = tour.stops_bounds
      overlay.south.to_f >= bounds[:south] - 1e-9 && overlay.north.to_f <= bounds[:north] + 1e-9 &&
        overlay.west.to_f >= bounds[:west] - 1e-9 && overlay.east.to_f <= bounds[:east] + 1e-9
    end

    it 'keeps a wide image wide' do
      overlay = overlay_for(400, 100)
      expect(projected_aspect(overlay)).to(be_within(0.001).of(4.0))
      expect(within_tour?(overlay)).to(be(true))
    end

    it 'keeps a tall image tall' do
      overlay = overlay_for(100, 300)
      expect(projected_aspect(overlay)).to(be_within(0.001).of(1.0 / 3))
      expect(within_tour?(overlay)).to(be(true))
    end

    it 'keeps the image ratio for a rotated overlay' do
      overlay = overlay_for(400, 100, rotation: 90)
      expect(projected_aspect(overlay)).to(be_within(0.001).of(4.0))
    end

    it 'keeps the ratio when the overlay is linked to the tour after upload' do
      # The admin uploads first, then links the overlay in a second request.
      overlay = build(:map_overlay, tour: nil, base_sixty_four: nil)
      overlay.file.attach(upload(400, 100))
      overlay.save!
      expect(overlay.north).to(be_nil)

      overlay = described_class.find(overlay.id)
      overlay.update!(tour:)
      expect(projected_aspect(overlay)).to(be_within(0.001).of(4.0))
      expect(overlay.file.blob.reload).to(be_analyzed)
    end

    it 'leaves bounds the curator already set' do
      overlay = overlay_for(400, 100, south: '1', north: '2', east: '3', west: '4')
      expect([overlay.south, overlay.north, overlay.east, overlay.west]).to(eq(['1', '2', '3', '4']))
    end
  end
end
