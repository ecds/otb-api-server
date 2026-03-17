class AccessRequestMailer < ApplicationMailer
  def access_request_email
    @access_request = params[:access_request]
    @tour_set = TourSet.find_by(subdir: @access_request.tour_set)
    Apartment::Tenant.switch! params[:tour_set]
    admins = TourSetAdmin.where(tour_set: @tour_set).map { |u| u.user.email }
    super_admins = User.where(super: true).pluck(:email)
    recipients = [ *admins, *super_admins ].uniq
    mail(to: recipients, subject: "OpenTour Access Request #{@tour_set.name}")
  end

  def access_request_tour_email
    @access_request = params[:access_request]
    @tour_set = TourSet.find_by(subdir: @access_request.tour_set)
    Apartment::Tenant.switch! params[:tour_set]
    admins = TourSetAdmin.where(tour_set: @tour_set).map { |u| u.user.email }
    super_admins = User.where(super: true).pluck(:email)
    recipients = [ *admins, *super_admins ].uniq
    @tour = Tour.find(params[:tour]) unless params[:tour].nil?
    mail(to: recipients, subject: "OpenTour Access Request for #{@tour.title}")
  end
end
