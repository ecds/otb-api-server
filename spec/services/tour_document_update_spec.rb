# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(TourDocumentUpdate) do
  let(:tour_set) { create(:tour_set) }
  # Unpublished so calculate_duration never calls Google Directions.
  let(:tour) { create(:tour, published: false) }
  let(:stops) { create_list(:stop, 3) }

  before do
    Apartment::Tenant.switch!(tour_set.subdir)
    stops.each_with_index { |stop, i| create(:tour_stop, tour:, stop:, position: i + 1) }
    tour.reload
  end

  def stop_entries(order = tour.tour_stops.order(:position))
    order.map { |ts| { relation_id: ts.id, id: ts.stop_id } }
  end

  it 'assigns allowed tour fields and ignores everything else' do
    described_class.call(tour, { title: 'Renamed', blank_map: true, slug: 'nope', id: 999 })
    tour.reload
    expect(tour.title).to(eq('Renamed'))
    expect(tour.blank_map).to(be(true))
    expect(tour.id).not_to(eq(999))
  end

  it 'sets theme and default mode from nested objects' do
    theme = create(:theme)
    mode = Mode.last
    described_class.call(tour, { theme: { id: theme.id }, mode: { id: mode.id } })
    expect(tour.reload.theme_id).to(eq(theme.id))
    expect(tour.mode_id).to(eq(mode.id))
  end

  it 'leaves lists alone when their key is absent' do
    expect { described_class.call(tour, { title: 'Only title' }) }.not_to(change { tour.tour_stops.count })
  end

  it 'reorders stops by the positions given' do
    entries = stop_entries.reverse.each_with_index.map { |e, i| e.merge(position: i + 1) }
    described_class.call(tour, { stops: entries })
    expect(tour.reload.tour_stops.order(:position).map(&:stop_id)).to(eq(stops.map(&:id).reverse))
    expect(tour.saved_stop_order).to(eq(stops.map(&:id).reverse))
  end

  it 'leaves positions alone when entries omit them' do
    described_class.call(tour, { stops: stop_entries.reverse })
    expect(tour.reload.tour_stops.order(:position).map(&:stop_id)).to(eq(stops.map(&:id)))
  end

  it 'leaves stops missing from the list untouched' do
    described_class.call(tour, { stops: stop_entries.first(1).map { |e| e.merge(title: 'Only this') } })
    expect(tour.reload.tour_stops.count).to(eq(3))
    expect(stops.first.reload.title).to(eq('Only this'))
  end

  it 'unlinks a stop marked _destroy without deleting the stop' do
    target = stop_entries.last
    described_class.call(tour, { stops: [target.merge(_destroy: true)] })
    expect(tour.reload.tour_stops.map(&:stop_id)).to(eq(stops.first(2).map(&:id)))
    expect(Stop.exists?(stops.last.id)).to(be(true))
  end

  it 'treats unlinking an already-removed join as a no-op' do
    target = stop_entries.last
    described_class.call(tour, { stops: [target.merge(_destroy: true)] })
    expect { described_class.call(tour, { stops: [target.merge(_destroy: true)] }) }.not_to(raise_error)
  end

  it 'links an existing stop at the end by default' do
    extra = create(:stop)
    described_class.call(tour, { stops: [{ id: extra.id }] })
    order = tour.reload.tour_stops.order(:position)
    expect(order.map(&:stop_id)).to(eq(stops.map(&:id) + [extra.id]))
    expect(order.last.position).to(eq(4))
  end

  it 'links at a given position' do
    extra = create(:stop)
    described_class.call(tour, { stops: [{ id: extra.id, position: 0 }] })
    expect(tour.reload.tour_stops.order(:position).first.stop_id).to(eq(extra.id))
  end

  it 'does not link the same stop twice when a request is retried' do
    extra = create(:stop)
    2.times { described_class.call(tour, { stops: [{ id: extra.id }] }) }
    expect(tour.reload.tour_stops.where(stop_id: extra.id).count).to(eq(1))
  end

  it 'updates stop fields in place' do
    entries = stop_entries
    entries[0] = entries[0].merge(title: 'New title', lat: 10, lng: 20, parking_address: 'Lot B')
    described_class.call(tour, { stops: entries })
    stop = stops.first.reload
    expect(stop.title).to(eq('New title'))
    expect([stop.lat.to_f, stop.lng.to_f]).to(eq([10.0, 20.0]))
    expect(stop.parking_address).to(eq('Lot B'))
  end

  it 'rejects a relation_id from another tour and changes nothing' do
    other = create(:tour, published: false)
    foreign = create(:tour_stop, tour: other, stop: create(:stop), position: 1)
    expect do
      described_class.call(tour, { title: 'Should roll back', stops: stop_entries + [{ relation_id: foreign.id, id: foreign.stop_id }] })
    end.to(raise_error(described_class::Invalid) { |e| expect(e.errors.first[:path]).to(eq('stops[3].relation_id')) })
    expect(tour.reload.title).not_to(eq('Should roll back'))
    expect(other.tour_stops.count).to(eq(1))
  end

  it 'rolls back everything when a record is invalid' do
    entries = stop_entries
    entries[1] = entries[1].merge(title: 'Changed')
    expect do
      described_class.call(tour, { title: '', stops: entries.reverse })
    end.to(raise_error(described_class::Invalid))
    expect(stops.second.reload.title).not_to(eq('Changed'))
    expect(tour.reload.tour_stops.order(:position).map(&:stop_id)).to(eq(stops.map(&:id)))
  end

  it 'reorders and edits tour media' do
    media = create_list(:medium, 2)
    joins = media.each_with_index.map { |m, i| create(:tour_medium, tour:, medium: m, position: i + 1) }
    described_class.call(tour, {
      media: [
        { relation_id: joins[1].id, id: media[1].id, caption: 'Now first', position: 1 },
        { relation_id: joins[0].id, id: media[0].id, position: 2 },
      ],
    })
    expect(tour.reload.tour_media.order(:position).map(&:medium_id)).to(eq([media[1].id, media[0].id]))
    expect(media[1].reload.caption).to(eq('Now first'))
  end

  it "links and unlinks a stop's own media" do
    stop = stops.first
    keep, drop = create_list(:medium, 2)
    dropped = create(:stop_medium, stop:, medium: drop, position: 1)
    entry = stop_entries.first.merge(media: [{ id: keep.id }, { relation_id: dropped.id, _destroy: true }])
    described_class.call(tour, { stops: [entry] })
    expect(stop.reload.stop_media.map(&:medium_id)).to(eq([keep.id]))
    expect(Medium.exists?(drop.id)).to(be(true))
  end

  it 'updates and unlinks flat pages' do
    pages = create_list(:flat_page, 2)
    joins = pages.each_with_index.map { |p, i| create(:tour_flat_page, tour:, flat_page: p, position: i + 1) }
    described_class.call(tour, {
      flat_pages: [
        { relation_id: joins[0].id, _destroy: true },
        { relation_id: joins[1].id, id: pages[1].id, title: 'About' },
      ],
    })
    expect(tour.reload.tour_flat_pages.map(&:flat_page_id)).to(eq([pages[1].id]))
    expect(pages[1].reload.title).to(eq('About'))
    expect(FlatPage.exists?(pages[0].id)).to(be(true))
  end

  it 'enables and disables travel modes individually' do
    keep, add = Mode.limit(2).to_a
    tour.update!(mode_ids: [keep.id])
    described_class.call(tour, { modes: [{ id: add.id }] })
    expect(tour.reload.mode_ids).to(contain_exactly(keep.id, add.id))
    described_class.call(tour, { modes: [{ id: keep.id, _destroy: true }] })
    expect(tour.reload.mode_ids).to(eq([add.id]))
  end

  it 'updates the map overlay bounds only for the tour\'s own overlay' do
    overlay = create(:map_overlay, tour:)
    described_class.call(tour, { map_overlay: { id: overlay.id, north: 1.5, south: 1, east: 2, west: 0 } })
    expect(overlay.reload.north.to_f).to(eq(1.5))

    described_class.call(tour, { map_overlay: { id: overlay.id + 1000, north: 9 } })
    expect(overlay.reload.north.to_f).to(eq(1.5))
  end
end
