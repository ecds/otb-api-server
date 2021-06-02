# frozen_string_literal: true

# app/controllers/v3/modes_controller.rb
module V3
  class ModesController < V3Controller

    # GET /modes
    def index
      render json: Mode.all
    end
  end
end
