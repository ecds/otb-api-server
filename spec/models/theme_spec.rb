# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Theme, type: :model) do
  it { is_expected.to(have_many(:tours)) }
end
