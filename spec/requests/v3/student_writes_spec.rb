# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('V3 writes by student authors', type: :request) do
  it 'refuses them' do
    tour_set = TourSet.first
    Apartment::Tenant.switch!(tour_set.subdir)
    student = create(:user, super: false)
    tour = create(:tour, published: false)
    stop = create(:stop, created_by_id: student.id)
    create(:tour_stop, tour:, stop:)
    create(:tour_author, tour:, user: student, student: true)
    allow_any_instance_of(V3Controller).to(receive(:current_user).and_return(student)) # rubocop:disable RSpec/AnyInstance

    delete "/#{tour_set.subdir}/stops/#{stop.id}"

    expect(response).to(have_http_status(:unauthorized))
    expect(Stop.exists?(stop.id)).to(be(true))
  end
end
