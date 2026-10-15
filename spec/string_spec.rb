# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(String) do
  it 'uses custom parameterize_intl method' do
    expect('My Awesome Tour'.parameterize_intl).to(eq('my-awesome-tour'))
    expect('Csodálatos túrám'.parameterize_intl).to(eq('csodalatos-turam'))
    expect('הסיור המדהים שלי'.parameterize_intl).to(eq('הסיור-המדהים-שלי'))
    expect('我的精 彩之旅!!'.parameterize_intl).to(eq('我的精-彩之旅'))
    expect('Мій чудовий тур'.parameterize_intl).to(eq('мій-чудовий-тур'))
    expect('جولتي الرائعة'.parameterize_intl).to(eq('جولتي-الرائعة'))
    expect('我的精 彩之旅!! (mix)'.parameterize_intl).to(eq('我的精-彩之旅-mix'))
    expect('💩 🤯 🤷🏼'.parameterize_intl).to(eq('💩-🤯-🤷🏼'))
  end
end
