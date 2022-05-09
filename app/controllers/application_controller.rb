# frozen_string_literal: true

# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include Response
  include ExceptionHandler
  include EcdsRailsAuthEngine::CurrentUser
  if Rails.env == 'test'
    include ActiveStorage::SetCurrent
  end

  before_action :set_no_cache_control, only: [:index, :show]

  def set_no_cache_control
    # Prevent the client from caching GET responses.
    # If you, for example, look at a tour at https://battle-of-atlanta.opentour.site
    # and your browser caches the API responses. then you go edit that tour
    # at https://opentour.site/admin/battle-or-atlanta, your browser will use some of
    # those previously cached responses. the problem is, those cached responses have a response header
    #
    # access-control-allow-origin: https://battle-of-atlanta.opentour.site
    #
    # But now your origin is https://opentour.site and the browser blocks the response
    # and throws a cross origin error
    response.headers['Cache-Control'] = 'no-cache, no-store, max-age=0, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '-1'
    expires_now()
    stale?(SecureRandom.hex(10))
  end
end
