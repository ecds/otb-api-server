# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(ProcessMediumVariantsJob) do
  let(:tour_set) { create(:tour_set) }

  before { Apartment::Tenant.switch!(tour_set.subdir) }

  it 'processes every variant for a medium in the given tenant' do
    medium = create(:medium)
    Apartment::Tenant.switch!('public')

    described_class.perform_now(tenant: tour_set.subdir, id: medium.id)

    Apartment::Tenant.switch!(tour_set.subdir)
    medium.reload
    Medium::VARIANT_SIZES.each_value do |size|
      expect(medium.file.variant(resize_to_limit: size).send(:processed?)).to(be(true))
    end
  end

  it 'does nothing when the medium is not in that tenant' do
    expect { described_class.perform_now(tenant: tour_set.subdir, id: -1) }.not_to(raise_error)
  end
end
