# frozen_string_literal: true

# app/controllers/v3/themes_controller.rb
module V3
  class ThemesController < V3Controller
    # GET /themes
    def index
      render json: Theme.all
    end

    # GET /themes/1
    def show
      render json: @record
    end

    # POST /themes
    def create
      head 405
    end

    # PATCH/PUT /themes/1
    def update
      head 405
    end

    # DELETE /themes/1
    def destroy
      head 405
    end

  private
    # Only allow a trusted parameter "white list" through.
    def set_record
      @record = Theme.find(params[:id])
    end
  end
end
