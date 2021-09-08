# frozen_string_literal: true

class V3Controller < ApplicationController
  include EcdsRailsAuthEngine::CurrentUser
  before_action :allowed?, only: [:show, :create, :update, :destroy]
  before_action :set_record, only: [:show, :update, :destroy]

  # GET /<record>/1
  def show
    render json: @record
  end

  # POST /v3/tour_media
  def create
    render json: {}, status: :unauthorized
  end

  # PATCH/PUT /media/1
  def update
    if crud_allowed?
      if @record.update(record_params)
        render json: @record
      else
        render json: serialize_errors, status: :unprocessable_entity
      end
    else
      render json: {}, status: :unauthorized
    end
  end

  def destroy
    if crud_allowed?
      @record.destroy
    else
      render json: {}, status: :unauthorized
    end
  end

  def serialize_errors
    errors = []
    if @record.nil?
      errors.push({ detail: 'Record not found', source: { pointer: 'data/attributes' } })
      # head 404
    else
      @record.errors.messages[:base].each do |error|
        errors.push({
          detail: error,
          source: {
            pointer: 'data/attributes'
          }
        })
      end
      # head 422
    end
    { errors: errors }
  end

  private

    def allowed?
      @allowed = @record&.published || crud_allowed?
    end

    def crud_allowed?
      current_user&.current_tenant_admin? || current_user.tours.present?
    end
end
