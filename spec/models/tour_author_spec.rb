require 'rails_helper'

RSpec.describe TourAuthor, type: :model do
  it { should belong_to(:tour) }
  it { should belong_to(:user) }
end
