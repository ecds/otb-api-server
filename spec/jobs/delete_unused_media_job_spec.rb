# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(DeleteUnusedMediaJob) do
  let(:tenant) { Apartment::Tenant.current }

  it 'deletes the unused media it was given' do
    unused = create(:medium)
    described_class.perform_now(tenant:, ids: [unused.id])
    expect(Medium.exists?(unused.id)).to(be(false))
  end

  it 'keeps a medium that has been used since the request' do
    medium = create(:medium)
    create(:stop_medium, stop: create(:stop), medium:)
    described_class.perform_now(tenant:, ids: [medium.id])
    expect(Medium.exists?(medium.id)).to(be(true))
  end

  it 'only touches the media it was given' do
    other = create(:medium)
    described_class.perform_now(tenant:, ids: [])
    expect(Medium.exists?(other.id)).to(be(true))
  end
end
