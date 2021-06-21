#
# Endpoint for through model for Stops and Media
#
class V3::StopMediaController < V3Controller
  # GET /v3/stop_media
  def index
    @stop_media = if params[:stop_id] && params[:medium_id]
      StopMedium.where(stop_id: params[:stop_id]).where(medium_id: params[:medium_id]).first || {}
    else
      StopMedium.all
    end
    render json: @stop_media
  end

  # GET /v3/stop_media/1
  def show
    render json: @record
  end

  # POST /v3/stop_media
  def create
    @record = StopMedium.new(record_params)

    if @record.save
      render json: @record, status: :created, location: "/#{Apartment::Tenant.current}/stop-medium/#{@record.id}"
    else
      render json: serialize_errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /v3/stop_media/1
  def update
    if @record.update(record_params)
      render json: @record
    else
      render json: serialize_errors, status: :unprocessable_entity
    end
  end

  # DELETE /v3/stop_media/1
  def destroy
    @record.destroy
  end

  private
    # Only allow a trusted parameter "white list" through.
    def record_params
      ActiveModelSerializers::Deserialization
          .jsonapi_parse(
            params, only: [
                  :medium, :stop, :position, :medium_id, :stop_id
              ]
          )
    end

    def set_record
      @record = StopMedium.find(params[:id])
    end
end
