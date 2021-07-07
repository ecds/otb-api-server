class V3::MapIconsController < V3Controller

  # GET /records
  def index
    @records = MapIcon.all

    render json: @records
  end

  # GET /records/1
  def show
    render json: @record
  end

  # POST /records
  def create
    @record = MapIcon.new(record_params)

    if @record.save
      render json: @record, status: :created
    else
      render json: serialize_errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /records/1
  def update
    if @record.update(record_params)
      render json: @record
    else
      render json: serialize_errors, status: :unprocessable_entity
    end
  end

  # DELETE /records/1
  def destroy
    @record.destroy
  end

  private
    # Only allow a trusted parameter "white list" through.
    def record_params
      ActiveModelSerializers::Deserialization
          .jsonapi_parse(
            params, only: [
                :base_sixty_four, :filename
              ]
          )
    end

    def set_record
      @record = MapIcon.find(params[:id])
    end
end
