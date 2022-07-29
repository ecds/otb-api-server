# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  # it { should have_one(:login) }
  # it { expect(User.reflect_on_association(:login).macro).to eq(:has_one) }

  context 'tour author across tenants' do
    it 'lists all tours across tenants' do
      # pw = Faker::Internet.password(min_length: 8)
      # u = User.create!(displayname: Faker::Movies::HitchhikersGuideToTheGalaxy.character)
      # Login.create!(identification: 'foo@bar.com', password: pw, password_confirmation: pw, user: u)
      # # RailsApiAuth uses `has_secure_password` The `authenticate` method returns
      # # the `Login` object. This just checks that the password authenticates
      # expect(u.login.authenticate(pw).user).to eq(u)
      TourSet.all.each { |tour_set| tour_set.delete }
      user = create(:user)
      create_list(:tour_set, 4)
      TourSet.all.each do |tour_set|
        Apartment::Tenant.switch! tour_set.subdir
        user.tours << create_list(:tour, 2)
      end
      expect(user.all_tours.count).to eq(8)
    end
  end

  context 'has login' do
    it 'has no provider' do
      user = create(:user)
      expect(user.provider).to be nil
    end

    it 'has no provider' do
      user = create(:user)
      login = create(:login, user_id: user.id)
      expect(user.provider).to eq(login.provider)
    end
  end

  context 'has default' do
    it 'terms accepted defaults to false' do
      user = create(:user)
      expect(user.terms_accepted).to be(false)
    end
  end
end
