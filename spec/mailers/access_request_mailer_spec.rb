require "rails_helper"

RSpec.describe AccessRequestMailer, type: :mailer do
  describe "access_request_email" do
    let(:site) { create(:tour_set) }
    let(:tour_set) { site.subdir }
    let(:user) { create(:user, super: false) }
    let(:access_request) { create(:access_request, user:, tour_set:) }
    let(:super_admin) { create(:user, super: true) }
    let(:admin) { create(:user, super: false, tour_sets: [ site ]) }
    let(:mail) { AccessRequestMailer.with(access_request:).access_request_email }

    it "renders the headers" do
      expect(super_admin.email).not_to be_nil
      expect(admin.email).not_to be_nil
      expect(mail.subject).to eq("OpenTour Access Request #{site.name}")
      expect(mail.to).to include(super_admin.email)
      expect(mail.to).to include(admin.email)
      expect(mail.from).to eq([ "noreply@opentour.site" ])
    end

    it "sends the email" do
      expect { mail.deliver_now }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end
end
