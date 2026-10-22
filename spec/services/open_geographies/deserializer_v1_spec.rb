# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(OpenGeographies::DeserializerV1) do
  def og_stop(name, order: nil)
    {
      uuid: SecureRandom.uuid,
      slug: name.parameterize,
      name:,
      geo: { point: { lat: 33.7, lon: -84.3 } },
      order:,
    }.compact
  end

  def titles(stops)
    described_class.new(stops:).call[:stops].pluck(:title)
  end

  it 'puts stops in their Open Geographies order and numbers them from 1' do
    result = described_class.new(stops: [og_stop('C', order: 30), og_stop('A', order: 10), og_stop('B', order: 20)]).call
    expect(result[:stops].pluck(:title)).to(eq(['A', 'B', 'C']))
    expect(result[:stops].pluck(:position)).to(eq([1, 2, 3]))
    expect(result[:stops].first[:next][:title]).to(eq('B'))
  end

  it 'keeps the listed order for stops with the same order' do
    expect(titles([og_stop('First', order: 1), og_stop('Second', order: 1)])).to(eq(['First', 'Second']))
  end

  it 'puts stops without an order last, in their listed order' do
    expect(titles([og_stop('X'), og_stop('B', order: 2), og_stop('Y'), og_stop('A', order: 1)]))
      .to(eq(['A', 'B', 'X', 'Y']))
  end
end
