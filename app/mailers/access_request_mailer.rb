# frozen_string_literal: true

class AccessRequestMailer < ApplicationMailer
  def access_request_email
    @access_request = params[:access_request]
    @tour_set = @access_request.tour_set
    Apartment::Tenant.switch!(@tour_set.subdir)
    recipients = (@tour_set.admins.pluck(:email) + User.where(super: true).pluck(:email)).uniq
    mail(to: recipients, subject: "OpenTour Access Request #{@tour_set.name}")
  end

  def access_request_tour_email
    @access_request = params[:access_request]
    @tour_set = TourSet.find_by(subdir: @access_request.tour_set)
    Apartment::Tenant.switch!(@access_request.tour_set.subdir)
    admins = TourSetAdmin.where(tour_set: @tour_set).map { |u| u.user.email }
    super_admins = User.where(super: true).pluck(:email)
    recipients = [*admins, *super_admins].uniq
    mail(to: recipients, subject: "OpenTour Access Request for #{@tour.title}")
  end
end
