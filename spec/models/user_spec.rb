# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(User, type: :model) do
  context 'when tour author across tenants' do
    it 'lists all tours across tenants' do
      TourSet.all.find_each(&:delete)
      user = create(:user)
      create_list(:tour_set, 4)
      TourSet.all.find_each do |tour_set|
        Apartment::Tenant.switch!(tour_set.subdir)
        user.tours << create_list(:tour, 2)
      end
      expect(user.all_tours.count).to(eq(8))
    end
  end

  context 'when has login' do
    it 'has no provider' do
      user = create(:user)
      expect(user.provider).not_to(be_nil)
    end
  end

  context 'when has default' do
    it 'terms accepted defaults to false' do
      user = create(:user)
      expect(user.terms_accepted).to(be(false))
    end
  end
end
