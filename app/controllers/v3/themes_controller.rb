# frozen_string_literal: true

# app/controllers/v3/themes_controller.rb
module V3
  class ThemesController < V3Controller
    # GET /themes
    def index
      @records = Theme.all

      render json: @records
    end

    # GET /themes/1
    def show
      render json: @record
    end

    # POST /themes
    def create
      @record = Theme.new(theme_params)

      if @record.save
        render json: @record, status: :created, location: @record
      else
        render json: serialize_errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /themes/1
    def update
      if @record.update(theme_params)
        render json: @record
      else
        render json: serialize_errors, status: :unprocessable_entity
      end
    end

    # DELETE /themes/1
    def destroy
      @record.destroy
    end

  private
    # Only allow a trusted parameter "white list" through.
    def theme_params
      params.fetch(:theme, {})
    end

    def set_record
      @record = Theme.find(params[:id])
    end
  end
end
