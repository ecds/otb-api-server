class V3::TourMediaController < V3Controller
  # GET /v3/tour_media
  def index
    @tour_media = if params[:tour_id] && params[:medium_id]
      TourMedium.where(tour_id: params[:tour_id]).where(medium_id: params[:medium_id]).first || {}
    else
      TourMedium.all
    end

    render json: @tour_media
  end

  # GET /v3/tour_media/1
  def show
    render json: @record
  end

  # POST /v3/tour_media
  def create
    @record = TourMedium.new(tour_medium_params)

    if @record.save
      render json: @record, status: :created, location: @record
    else
      render json: serialize_errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /v3/tour_media/1
  def update
    if @record.update(tour_medium_params)
      render json: @record
    else
      render json: serialize_errors, status: :unprocessable_entity
    end
  end

  # DELETE /v3/tour_media/1
  def destroy
    @record.destroy
  end

  private
    # Only allow a trusted parameter "white list" through.
    def tour_medium_params
      ActiveModelSerializers::Deserialization
          .jsonapi_parse(
            params, only: [
                  :medium, :tour, :position
              ]
          )
    end

    def set_record
      @record = TourMedium.find(params[:id])
    end
end
