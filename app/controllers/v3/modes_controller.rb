# frozen_string_literal: true

# app/controllers/v3/modes_controller.rb
module V3
  class ModesController < ApplicationController
    # GET /modes
    def index
      json_response Mode.all
    end

    def show
      json_response Mode.find(params[:id])
    end
  end
end
