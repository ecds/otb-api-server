# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(StopSlug, type: :model) do
  it { should belong_to(:stop) }

  it 'should get reassigned' do
    title = Faker::Movies::HitchhikersGuideToTheGalaxy.location
    stop1 = create(:stop, title:)
    slug = StopSlug.find_by(slug: title.parameterize_intl)
    expect(slug.stop).to(eq(stop1))
    stop1.update(title: 'changed')
    expect(stop1.stop_slugs).to(include(slug))
    stop2 = create(:stop, title:)
    expect(stop1.stop_slugs).not_to(include(slug))
    expect(stop2.stop_slugs).to(include(slug))
  end
end
