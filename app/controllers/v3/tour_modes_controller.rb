# frozen_string_literal: true

# app/controllers/v3/tour_modes_controller.rb
module V3
  class TourModesController < V3Controller
    authorize_resource

    # GET /tour_sets
    def index
      @tour_modes = TourMode.all

      render json: @tour_modes
    end

    # GET /v3/tour_media/1
    def show
      tour_mode = TourMode.find(params[:id])
      render json: tour_mode
    end
  end
end
