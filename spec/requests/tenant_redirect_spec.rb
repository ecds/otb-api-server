# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('Renamed tenant redirects', type: :request) do
  it 'redirects a request using an old subdir to the current one' do
    tour_set = create(:tour_set)
    old_subdir = tour_set.subdir
    tour_set.update!(name: 'A Totally Different Name')

    get "/#{old_subdir}/v4/public/modes"

    expect(response).to(have_http_status(:permanent_redirect))
    expect(response.headers['Location']).to(eq("/#{tour_set.subdir}/v4/public/modes"))
  end

  it 'does not redirect a subdir that was never renamed' do
    tour_set = create(:tour_set)

    get "/#{tour_set.subdir}/v4/public/modes"

    expect(response).not_to(have_http_status(:permanent_redirect))
  end
end
