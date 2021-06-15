class V3::MapOverlaysController < V3Controller
  before_action :set_map_overlay, only: [:show, :update, :destroy]

  def show
    render json: @map_overlay
  end

  def create
    @map_overlay = MapOverlay.new(map_overlay_params)
    if @map_overlay.save
      render json: @map_overlay, status: :created
    else
      render json: @map_overlay.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /stops/1
  def update
    if @map_overlay.update(map_overlay_params)
      # render json: @stop
      head :no_content
    else
      render json: @map_overlay.errors, status: :unprocessable_entity
    end
  end

  # DELETE /stops/1
  def destroy
    if @map_overlay
      @map_overlay.destroy
    end
    head :no_content
  end

  private

    # Only allow a trusted parameter "white list" through.
    def map_overlay_params
      ActiveModelSerializers::Deserialization
          .jsonapi_parse(
            params, only: [
                  :south, :east, :north, :west, :base_sixty_four, :title, :tour, :stop
              ]
          )
    end

    def set_map_overlay
      @map_overlay = MapOverlay.find_by(id: params[:id])
    end
end
