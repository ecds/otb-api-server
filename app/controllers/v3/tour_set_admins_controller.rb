# frozen_string_literal: true

module V3
  class TourSetAdminsController < V3Controller
    # GET /tour_set_admins
    def index
      if current_user && current_user.super
        @records = TourSetAdmin.all

        render json: @records
      else
        head 401
      end
    end

    # GET /tour_set_admins/1
    def show
      render json: @record
    end

    # POST /tour_set_admins
    def create
      @record = TourSetAdmin.new(tour_set_admin_params)

      if @record.save
        render json: @record, status: :created, location: @record
      else
        render json: serialize_errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /tour_set_admins/1
    def update
      if @record.update(tour_set_admin_params)
        render json: @record
      else
        render json: serialize_errors, status: :unprocessable_entity
      end
    end

    # DELETE /tour_set_admins/1
    def destroy
      @record.destroy
    end

    private
      # Only allow a trusted parameter "white list" through.
      def tour_set_admin_params
        params.fetch(:tour_set_admin, {})
      end

      def set_record
        @record = TourSetAdmin.find(params[:id])
      end
  end
end
