class V3::MapIconsController < ApplicationController
  before_action :set_map_icon, only: [:show, :update, :destroy]

  # GET /map_icons
  def index
    @map_icons = MapIcon.all

    render json: @map_icons
  end

  # GET /map_icons/1
  def show
    render json: @map_icon
  end

  # POST /map_icons
  def create
    @map_icon = MapIcon.new(map_icon_params)

    if @map_icon.save
      render json: @map_icon, status: :created
    else
      render json: @map_icon.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /map_icons/1
  def update
    if @map_icon.update(map_icon_params)
      render json: @map_icon
    else
      render json: @map_icon.errors, status: :unprocessable_entity
    end
  end

  # DELETE /map_icons/1
  def destroy
    @map_icon.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_map_icon
      @map_icon = MapIcon.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def map_icon_params
      ActiveModelSerializers::Deserialization
          .jsonapi_parse(
            params, only: [
                :base_sixty_four, :title
              ]
          )
    end
end
