# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "noreply@opentour.site"
  layout "mailer"
end
