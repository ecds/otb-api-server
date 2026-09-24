# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(AccessRequest, type: :model) do
  let(:tour_set) { create(:tour_set) }
  let(:user) { create(:user, super: false, tour_sets: []) }
  let(:access_request) { create(:access_request, tour_set:, user:) }

  describe 'validations' do
    it 'is invalid when a user already has a pending request for the same tour set' do
      create(:access_request, tour_set:, user:)
      duplicate = build(:access_request, tour_set:, user:)
      expect(duplicate).not_to(be_valid)
    end
  end

  describe '#requested_tours' do
    it 'returns empty array when no tour ids are set' do
      expect(access_request.requested_tours).to(be_empty)
    end

    it 'returns the tours matching stored tour_ids' do
      Apartment::Tenant.switch!(tour_set.subdir)
      tours = create_list(:tour, 2)
      request_with_tours = create(:access_request, tour_set:, tour_ids: [tours.first.id, tours.last.id])
      expect(request_with_tours.requested_tours).to(include(tours.first))
      expect(request_with_tours.requested_tours).to(include(tours.last))
    end
  end

  describe '#search_data' do
    it 'includes expected fields' do
      data = access_request.search_data
      expect(data[:id]).to(eq(access_request.id))
      expect(data[:email]).to(eq(user.email))
      expect(data[:site]).to(eq(tour_set.name))
      expect(data[:tours]).to(eq([]))
    end
  end

  describe 'approval via #update' do
    it 'adds the tour set to the user and destroys the request when approved for whole site' do
      access_request
      expect(user.tour_sets).not_to(include(tour_set))
      access_request.update(approved: true)
      user.reload
      expect(user.tour_sets).to(include(tour_set))
      expect(described_class.find_by(id: access_request.id)).to(be_nil)
    end

    it 'adds specific tours to the user and destroys the request when approved for tours' do
      Apartment::Tenant.switch!(tour_set.subdir)
      tours = create_list(:tour, 2)
      request_with_tours = create(:access_request, tour_set:, user:, tour_ids: [tours.first.id, tours.last.id])
      request_with_tours.update(approved: true)
      user.reload
      expect(user.tours).to(include(tours.first))
      expect(user.tours).to(include(tours.last))
      expect(user.tour_sets).not_to(include(tour_set))
      expect(described_class.find_by(id: request_with_tours.id)).to(be_nil)
    end

    it 'destroys the request without granting access when denied' do
      access_request
      access_request.update(approved: false)
      user.reload
      expect(user.tour_sets).not_to(include(tour_set))
      expect(described_class.find_by(id: access_request.id)).to(be_nil)
    end
  end
end
