# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(OpenTourApi::Application::DirectoryElevator) do
  let(:inner) { ->(_env) { [200, {}, [Apartment::Tenant.current]] } }
  let(:elevator) { described_class.new(inner) }
  let(:tour_set) { create(:tour_set) }

  def get(path)
    elevator.call(Rack::MockRequest.env_for(path))
  end

  it 'returns 404 for an unknown first path segment without calling the app' do
    allow(inner).to(receive(:call).and_call_original)
    status, = get('/careers')
    expect(status).to(eq(404))
    expect(inner).not_to(have_received(:call))
  end

  it 'returns 404 for crawler files like robots.txt' do
    status, = get('/robots.txt')
    expect(status).to(eq(404))
  end

  it 'switches to a known tenant' do
    status, _, body = get("/#{tour_set.subdir}/v4/public/tours")
    expect(status).to(eq(200))
    expect(body.first).to(eq(tour_set.subdir))
  end

  it 'passes ignored paths through in the public schema' do
    status, _, body = get('/health')
    expect(status).to(eq(200))
    expect(body.first).to(eq('public'))
  end

  it 'redirects a renamed tenant to its current subdir' do
    TourSetSubdirHistory.create!(subdir: 'old-name', tour_set:)
    status, headers, = get('/old-name/v4/public/tours')
    expect(status).to(eq(308))
    expect(headers['Location']).to(eq("/#{tour_set.subdir}/v4/public/tours"))
  end
end
