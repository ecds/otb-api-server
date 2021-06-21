# frozen_string_literal: true

class V3::FlatPagesController < V3Controller
  before_action :set_record, only: [:show, :update, :destroy]
  #authorize_resource

  # GET /v3/records
  def index
    @records = FlatPage.all

    render json: @records
  end

  # GET /v3/records/1
  def show
    render json: @record
  end

  # POST /v3/records
  def create
    if @allowed
      @record = FlatPage.new(record_params)

      if @record.save
        render json: @record, status: :created, location: "/#{Apartment::Tenant.current}/flat-pages/#{@record.id}"
      else
        render json: serialize_errors, status: :unprocessable_entity
      end
    else
      head 401
    end
  end

  # PATCH/PUT /v3/records/1
  def update
    if @allowed
      if @record.update(record_params)
        render json: @record
      else
        render json: serialize_errors, status: :unprocessable_entity
      end
    else
      head 401
    end
  end

  # DELETE /v3/records/1
  def destroy
    if @allowed
      @record.destroy
    else
      head 401
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_record
      @record = FlatPage.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def record_params
      ActiveModelSerializers::Deserialization
          .jsonapi_parse(
            params, only: [
                  :title, :body, :tours
              ]
          )
    end
end
