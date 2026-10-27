# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(TourAccess) do
  let(:tour) { create(:tour, published: false) }
  let(:student) { create(:user, super: false) }
  let(:author) { create(:user, super: false) }

  before do
    create(:tour_author, tour:, user: student, student: true)
    create(:tour_author, tour:, user: author)
  end

  it 'lets tour authors do everything' do
    access = described_class.new(author, tour)
    expect([access.edit?, access.publish?, access.delete_tour?]).to(all(be(true)))
    expect(access.remove?(create(:stop))).to(be(true))
  end

  it 'lets student authors edit, but not publish or delete the tour' do
    access = described_class.new(student, tour)
    expect(access.edit?).to(be(true))
    expect(access.student?).to(be(true))
    expect(access.publish?).to(be(false))
    expect(access.delete_tour?).to(be(false))
  end

  it 'lets student authors remove only what they added' do
    access = described_class.new(student, tour)
    expect(access.remove?(create(:stop, created_by_id: student.id))).to(be(true))
    expect(access.remove?(create(:stop, created_by_id: author.id))).to(be(false))
    expect(access.remove?(create(:stop))).to(be(false))
    expect(access.remove?(create(:medium, created_by_id: student.id))).to(be(true))
  end

  it "doesn't let student authors remove anything once the tour is published" do
    tour.update!(published: true)
    access = described_class.new(student, tour)
    expect(access.remove?(create(:stop, created_by_id: student.id))).to(be(false))
  end

  it 'lists what a student author can remove, for the admin' do
    mine = create(:stop, created_by_id: student.id)
    theirs = create(:stop, created_by_id: author.id)
    create(:tour_stop, tour:, stop: mine)
    create(:tour_stop, tour:, stop: theirs)

    data = described_class.new(student, tour).as_json
    expect(data).to(include(student: true, publish: false, removable_stop_ids: [mine.id]))
    expect(described_class.new(author, tour).as_json).to(include(student: false, publish: true, removable_stop_ids: nil))
  end

  it 'gives people who are not authors nothing' do
    access = described_class.new(create(:user, super: false), tour)
    expect(access.edit?).to(be(false))
    expect(access.publish?).to(be(false))
  end

  it 'treats a signed-out user as having no access' do
    access = described_class.new(User.new, tour)
    expect(access.edit?).to(be(false))
    expect(access.remove?(create(:stop))).to(be(false))
  end
end
