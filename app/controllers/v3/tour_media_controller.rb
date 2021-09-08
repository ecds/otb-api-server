class V3::TourMediaController < V3::TourRelationsController
  # GET /v3/tour_media
  def index
    # @tour_media = if params[:tour_id] && params[:medium_id]
    #   TourMedium.where(tour_id: params[:tour_id]).where(medium_id: params[:medium_id]).first || {}
    # else
    #   TourMedium.all
    # end

    @tour_media = TourMedium.all

    unless current_user&.current_tenant_admin? || current_user.tours.present?
      @tour_media = @tour_media.reject { |tour_medium| !tour_medium.tour.published }
    end

    render json: @tour_media
  end

  def destroy
    head 405
  end

  private
    # Only allow a trusted parameter "white list" through.
    def record_params
      ActiveModelSerializers::Deserialization
          .jsonapi_parse(
            params, only: [
                  :medium, :tour, :position
              ]
          )
    end

    def set_record
      _record = TourMedium.find(params[:id])
      @record = _record&.published || @allowed ? _record : TourMedium.new(id: params[:id])
    end
end
