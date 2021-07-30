# frozen_string_literal: true

class V3Controller < ApplicationController
  include EcdsRailsAuthEngine::CurrentUser
  before_action :set_record, only: [:show, :update, :destroy]
  before_action :allowed?, only: [:create, :update, :destroy]

  def destroy
    if @allowed
      @record.destroy
    else
      head 401
    end
  end

  def serialize_errors
    errors = []
    @record.errors.messages[:base].each do |error|
      errors.push({
        detail: error,
        source: {
          pointer: 'data/attributes'
        }
      })
    end
    { errors: errors }
  end

  private

    def allowed?
      @allowed = current_user && current_user.current_tenant_admin?
    end
end
