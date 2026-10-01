# frozen_string_literal: true

module V3
  class TourSetAdminsController < V3Controller
    # GET /tour_set_admins
    def index
      if current_user&.super || current_user&.current_tenant_admin?
        render(json: TourSetAdmin.all)
      else
        head(:unauthorized)
      end
    end

    # GET /tour_set_admins/1
    def show
      head(:method_not_allowed)
      # if current_user&.super || current_user&.current_tenant_admin?
      #   render json: @record
      # else
      #   head 401
      # end
    end

    # POST /tour_set_admins
    def create
      head(:method_not_allowed)
      # @record = TourSetAdmin.new(tour_set_admin_params)

      # if @record.save
      #   render json: @record, status: :created, location: @record
      # else
      #   render json: serialize_errors, status: :unprocessable_entity
      # end
    end

    # PATCH/PUT /tour_set_admins/1
    def update
      head(:method_not_allowed)
    end

    # DELETE /tour_set_admins/1
    def destroy
      head(:method_not_allowed)
    end

    private

    # Only allow a trusted parameter "white list" through.
    # def tour_set_admin_params
    #   params.fetch(:tour_set_admin, {})
    # end

    def set_record
      @record = TourSetAdmin.find(params[:id])
    end
  end
end
