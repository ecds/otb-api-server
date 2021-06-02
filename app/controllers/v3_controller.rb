# frozen_string_literal: true

class V3Controller < ApplicationController
  include EcdsRailsAuthEngine::CurrentUser
  # check_authorization

  rescue_from CanCan::AccessDenied do |exception|
    head 401
  end
end
