# frozen_string_literal: true

# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include Response
  include ExceptionHandler
  include EcdsRailsAuthEngine::CurrentUser
  if Rails.env == 'test'
    include ActiveStorage::SetCurrent
  end
end
