# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(CrudAccess) do
  let(:tour) { create(:tour, published: false) }
  let(:other_tour) { create(:tour, published: false) }
  let(:author) { create(:user, super: false) }
  let(:student) { create(:user, super: false) }

  before do
    create(:tour_author, tour:, user: author)
    create(:tour_author, tour:, user: student, student: true)
  end

  it 'only knows the models the admin uses' do
    expect(described_class.model?('stop')).to(be(true))
    expect(described_class.model?('login')).to(be(false))
  end

  describe 'records on tours the user has no part in' do
    it 'refuses them' do
      stop = create(:stop)
      create(:tour_stop, tour: other_tour, stop:)
      access = described_class.new(author)
      expect(access.update?(stop)).to(be(false))
      expect(access.destroy?(stop)).to(be(false))
      expect(access.destroy?(other_tour)).to(be(false))
      expect(access.create?(TourStop.new(tour: other_tour, stop: create(:stop)))).to(be(false))
    end
  end

  describe 'site-level records' do
    it "aren't for tour authors" do
      access = described_class.new(author)
      expect(access.create?(TourSetAdmin.new(user: author, tour_set: TourSet.first))).to(be(false))
      expect(access.update?(TourSet.first)).to(be(false))
      expect(access.update?(TourAuthor.find_by(user: student))).to(be(false))
    end

    it 'are for super users' do
      expect(described_class.new(create(:user, super: true)).update?(TourAuthor.find_by(user: student))).to(be(true))
    end
  end

  it 'lets users update only their own account' do
    expect(described_class.new(author).update?(author)).to(be(true))
    expect(described_class.new(author).update?(student)).to(be(false))
  end

  describe 'tours' do
    it 'lets authors update and delete their tours' do
      access = described_class.new(author)
      expect(access.update?(tour, 'published' => true)).to(be(true))
      expect(access.destroy?(tour)).to(be(true))
    end

    it "doesn't let student authors publish or delete them" do
      access = described_class.new(student)
      expect(access.update?(tour, 'title' => 'New title')).to(be(true))
      expect(access.update?(tour, 'published' => true)).to(be(false))
      expect(access.destroy?(tour)).to(be(false))
    end
  end

  describe 'stops' do
    it 'lets student authors start new ones and remove their own before publishing' do
      access = described_class.new(student)
      expect(access.create?(Stop.new(title: 'New'))).to(be(true))

      mine = create(:stop, created_by_id: student.id)
      join = create(:tour_stop, tour:, stop: mine)
      expect(access.destroy?(join)).to(be(true))
      expect(access.destroy?(mine)).to(be(true))

      tour.update!(published: true)
      expect(described_class.new(student).destroy?(join)).to(be(false))
    end

    it "doesn't let student authors remove someone else's" do
      theirs = create(:stop, created_by_id: author.id)
      join = create(:tour_stop, tour:, stop: theirs)
      access = described_class.new(student)
      expect(access.update?(theirs)).to(be(true))
      expect(access.destroy?(join)).to(be(false))
      expect(access.destroy?(theirs)).to(be(false))
    end
  end

  describe 'media' do
    it "lets student authors unlink their own images from a stop, but not someone else's" do
      stop = create(:stop)
      create(:tour_stop, tour:, stop:)
      mine = create(:stop_medium, stop:, medium: create(:medium, created_by_id: student.id))
      theirs = create(:stop_medium, stop:, medium: create(:medium, created_by_id: author.id))
      access = described_class.new(student)
      expect(access.destroy?(mine)).to(be(true))
      expect(access.destroy?(theirs)).to(be(false))
    end
  end
end
