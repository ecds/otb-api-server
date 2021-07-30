# frozen_string_literal: true

# /app/controllers/v3/tour_stops_controller.rb
class V3::TourStopsController < V3Controller
  # GET /stops
  def index
    @records = if params[:fastboot] == 'true'
      nil
    elsif params[:tour] && params[:slug]
      tour = Tour.find(params[:tour])
      if tour.published || allowed?
        stop = Stop.by_slug_and_tour(params[:slug], params[:tour]).first
        TourStop.find_by(tour: Tour.find(params[:tour]), stop: stop)
      else
        {}
      end
    elsif current_user.current_tenant_admin?
      TourStop.all
    else
      Tour.published.map { |tour| tour.tour_stops }.flatten.uniq
    end
    if @records.nil?
      render json: { data: { type: 'tour_stops', id: 0 } }
    else
      render json: @records, include: ['stop']
    end
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
    head 401
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
    head 401
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
        @record = TourStop.find(params[:id])
      end

      def allowed?
        @allowed = current_user&.current_tenant_admin? || current_user.tours&.any? { |tour| Tour.all.include?(tour) }
        return @allowed
      end
end
