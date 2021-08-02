# frozen_string_literal: true

class V3::FlatPagesController < V3Controller
  before_action :set_record, only: [:show, :update, :destroy]
  #authorize_resource

  # GET /v3/records
  def index
    @records = if current_user.current_tenant_admin?
      FlatPage.all
    elsif current_user.tours.present?
      current_user.tours.map { |tour| tour.flat_pages }.flatten.uniq
    else
      Tour.published.map { |tour| tour.flat_pages }.flatten.uniq
    end
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


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_record
      _record = FlatPage.find(params[:id])
      @record = _record.published || @allowed ? _record : FlatPage.new(id: params[:id])
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

    def allowed?
      @allowed = current_user&.current_tenant_admin? || current_user.tours&.any? { |tour| Tour.all.include?(tour) }
    end
end
