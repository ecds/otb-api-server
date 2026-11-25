# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('V3 publishing tours with images missing alt text', type: :request) do
  let(:tour_set) { TourSet.first }
  let(:tour) { create(:tour, published: false) }

  before do
    Apartment::Tenant.switch!(tour_set.subdir)
    create(:tour_medium, tour:, medium: create(:medium, alt_text: nil))
    allow_any_instance_of(V3Controller).to(receive(:current_user).and_return(create(:user, super: true))) # rubocop:disable RSpec/AnyInstance
  end

  def publish_from(origin)
    patch(
      "/#{tour_set.subdir}/tours/#{tour.id}",
      params: { data: { type: 'tours', id: tour.id, attributes: { published: true } } }.to_json,
      headers: { 'Content-Type': 'application/vnd.api+json', Origin: origin },
    )
  end

  it 'is allowed from the production admin' do
    publish_from('https://opentour.site')
    expect(response).to(have_http_status(:ok))
    expect(tour.reload.published).to(be(true))
  end

  it 'is still refused from the dev admin' do
    publish_from('https://dev.opentour.site')
    expect(response).to(have_http_status(:unprocessable_entity))
    expect(tour.reload.published).to(be(false))
  end
end
