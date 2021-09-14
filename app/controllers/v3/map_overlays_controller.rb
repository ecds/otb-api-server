class V3::MapOverlaysController < V3Controller
  def create
    if crud_allowed?
      @record = MapOverlay.new(record_params)
      if @record.save
        render json: @record, status: :created
      else
        render json: serialize_errors, status: :unprocessable_entity
      end
    else
      head 401
    end
  end

  private

    # Only allow a trusted parameter "white list" through.
    def record_params
      ActiveModelSerializers::Deserialization
          .jsonapi_parse(
            params, only: [
                  :south, :east, :north, :west, :base_sixty_four, :filename, :tour, :stop
              ]
          )
    end

    def set_record
      _record = MapOverlay.find(params[:id])
      @record = _record&.published || @allowed ? _record : MapOverlay.new(id: params[:id])
    end
end
