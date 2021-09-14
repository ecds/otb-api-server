require 'rails_helper'

RSpec.describe StopSlug, type: :model do
  it { should belong_to(:stop) }
end
