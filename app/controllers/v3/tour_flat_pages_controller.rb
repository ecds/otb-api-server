# frozen_string_literal: true

# /app/controllers/v3/tour_stops_controller.rb
class V3::TourFlatPagesController < V3Controller
  # GET /stops
  def index
    @tour_flat_pages = TourFlatPage.all

    unless current_user&.current_tenant_admin? || current_user.tours.present?
      @tour_flat_pages = @tour_flat_pages.reject { |tour_flat_page| !tour_flat_page.tour.published }
    end

    render json: @tour_flat_pages
  end

  # GET /stops/1
  def show
    if @record&.tour.published || allowed?
      render json: @record
    else
      render json: { data: {} }
    end
    # render json: { data: {} } if @record.nil?
    # render json: @record, include: ['stop']
  end

  # POST /stops
  def create
    # Not created via the API
    head 405
  end

  # PATCH/PUT /stops/1
  def update
    if @allowed
      if @record.update(tour_stop_params)
        render json: @record, location: "/#{Apartment::Tenant.current}/tour_stops/#{@record.id}"
      else
        render json: serialize_errors, status: :unprocessable_entity
      end
    else
      head 401
    end
  end

  # DELETE /stops/1
  def destroy
    # Not deleted via the API
    head 405
  end

    private

      # Only allow a trusted parameter "white list" through.
      def tour_stop_params
        ActiveModelSerializers::Deserialization
            .jsonapi_parse(
              params, only: [
                    :stop, :tour, :position
                ]
            )
      end

      def set_record
        @record = TourFlatPage.find(params[:id])
      end

      def allowed?
        @allowed = current_user&.current_tenant_admin? || current_user.tours&.any? { |tour| Tour.all.include?(tour) }
        return @allowed
      end
end
