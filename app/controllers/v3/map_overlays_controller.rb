class V3::MapOverlaysController < V3Controller

  def show
    render json: @record
  end

  def create
    @record = MapOverlay.new(record_params)
    if @record.save
      render json: @record, status: :created
    else
      render json: serialize_errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /stops/1
  def update
    if @record.update(record_params)
      # render json: @stop
      head :no_content
    else
      render json: serialize_errors, status: :unprocessable_entity
    end
  end

  # DELETE /stops/1
  def destroy
    if @record
      @record.destroy
    end
    head :no_content
  end

  private

    # Only allow a trusted parameter "white list" through.
    def record_params
      ActiveModelSerializers::Deserialization
          .jsonapi_parse(
            params, only: [
                  :south, :east, :north, :west, :base_sixty_four, :title, :tour, :stop
              ]
          )
    end

    def set_record
      @record = MapOverlay.find(params[:id])
    end
end
