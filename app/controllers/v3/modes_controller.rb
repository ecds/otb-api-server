# frozen_string_literal: true

# app/controllers/v3/modes_controller.rb
module V3
  class ModesController < ApplicationController

    # GET /modes
    def index
      render json: Mode.all
    end
  end
end
