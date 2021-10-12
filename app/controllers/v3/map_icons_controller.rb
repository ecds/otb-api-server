module V3
  class MapIconsController < V3Controller

    def index
      render json: MapIcon.all
    end

    def create
      if crud_allowed?
        @record = MapIcon.new(record_params)
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
                :base_sixty_four, :filename, :stop
              ]
            )
      end

      def set_record
        _record = MapIcon.find(params[:id])
        @record = _record&.published || @allowed ? _record : MapIcon.new(id: params[:id])
      end
  end
end
