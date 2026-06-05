# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(StopMedium, type: :model) do
  it { is_expected.to(belong_to(:stop)) }
  it { is_expected.to(belong_to(:medium)) }
end
