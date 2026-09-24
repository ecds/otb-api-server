# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/access_request_mailer
class AccessRequestMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/access_request_mailer/access_request_email
  delegate :access_request_email, to: :AccessRequestMailer
end
