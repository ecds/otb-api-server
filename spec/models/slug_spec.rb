require 'rails_helper'

RSpec.describe Slug, type: :model do
  it { should belong_to(:tour) }
end
