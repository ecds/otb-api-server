module V3
  class StopMediaController < V3::TourRelationsController
    # GET /v3/stop_media
    def index
      # @stop_media = if params[:tour_id] && params[:medium_id]
      #   StopMedium.where(tour_id: params[:tour_id]).where(medium_id: params[:medium_id]).first || {}
      # else
      #   StopMedium.all
      # end

      @stop_media = StopMedium.all

      unless current_user&.current_tenant_admin? || current_user.tours.present?
        @stop_media = @stop_media.reject { |stop_medium| !stop_medium.stop.published }
      end

      render json: @stop_media
    end

    private
      # Only allow a trusted parameter "white list" through.
      def record_params
        ActiveModelSerializers::Deserialization
            .jsonapi_parse(
              params, only: [
                    :medium, :stop, :position
                ]
            )
      end

      def set_record
        _record = StopMedium.find(params[:id])
        @record = _record&.published || @allowed ? _record : StopMedium.new(id: params[:id])
      end
  end
end
