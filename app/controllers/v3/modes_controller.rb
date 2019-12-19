# frozen_string_literal: true

# app/controllers/v3/modes_controller.rb
module V3
  class ModesController < V3Controller
    # before_action :set_mode, only: [:show, :update, :destroy]
    authorize_resource

    # GET /modes
    def index
      @modes = Mode.all

      render json: @modes
    end
  end
end
