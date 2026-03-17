require 'rails_helper'

RSpec.describe Slug, type: :model do
  it { should belong_to(:tour) }

  it "should get reassigned" do
    title = Faker::Movies::HitchhikersGuideToTheGalaxy.location
    tour1 = create(:tour, title:)
    slug = Slug.find_by(slug: title.parameterize_intl)
    expect(slug.tour).to eq(tour1)
    tour1.update(title: 'changed')
    expect(tour1.slugs).to include(slug)
    tour2 = create(:tour, title:)
    expect(tour1.slugs).not_to include(slug)
    expect(tour2.slugs).to include(slug)
  end
end
