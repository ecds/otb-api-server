# frozen_string_literal: true

class V3::TourFlatPagesController < V3Controller
  # GET /v3/tour_flat_pages
  def index
    @records = TourFlatPage.all

    render json: @records
  end

  # GET /v3/tour_flat_pages/1
  def show
    render json: @record
  end

  # POST /v3/tour_flat_pages
  def create
    if @allowed
      @record = TourFlatPage.new(tour_flat_page_params)

      if @record.save
        render json: @record, status: :created, location: "/#{Apartment::Tenant.current}/flat-pages/#{@record.id}"
      else
        render json: serialize_errors, status: :unprocessable_entity
      end
    else
      head 401
    end
  end

  # PATCH/PUT /v3/tour_flat_pages/1
  def update
    if @allowed
      if @record.update(tour_flat_page_params)
        render json: @record
      else
        render json: serialize_errors, status: :unprocessable_entity
      end
    else
      head 401
    end
  end

  # DELETE /v3/tour_flat_pages/1
  def destroy
    if @allowed
      @record.destroy
    else
      head 401
    end
  end

  private
    # Only allow a trusted parameter "white list" through.
    def tour_flat_page_params
      ActiveModelSerializers::Deserialization
          .jsonapi_parse(
            params, only: [
                  :tour, :flat_page, :position
              ]
          )
    end

    def set_record
      @record = TourFlatPage.find(params[:id])
    end
end
