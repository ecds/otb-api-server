# frozen_string_literal: true

# /app/controllers/v3/stops_controller.rb
# module V3
class V3::StopsController < V3Controller
  # GET /stops
  def index
    @records = if current_user.current_tenant_admin?
      Stop.all
    elsif current_user.tours.present?
      current_user.tours.map { |tour| tour.stops }.flatten.uniq
    else
      Tour.published.map { |tour| tour.stops }.flatten.uniq
    end
    render json: @records
  end

  # GET /stops/1
  # Direct access to stops goes throught V3:TourStopsController
  def show
    render json: {}
  end

  # POST /stops
  def create
    if @allowed
      @record = Stop.new(stop_params)
      if @record.save
        render json: @record, status: :created, location: "/#{Apartment::Tenant.current}/#{@record.id}"
      else
        render json: serialize_errors, status: :unprocessable_entity
      end
    else
      head 401
    end
  end

  # PATCH/PUT /stops/1
  def update
    if @allowed
      if @record.update(stop_params)
        render json: @record, location: "/#{Apartment::Tenant.current}/stops/#{@record.id}"
      else
        render json: serialize_errors, status: :unprocessable_entity
      end
    else
      head 401
    end
  end

    private

      # Only allow a trusted parameter "white list" through.
      def stop_params
        ActiveModelSerializers::Deserialization
            .jsonapi_parse(
              params, only: [
                    :title, :description, :lat, :lng,
                    :parking_lat, :parking_lng, :media,
                    :address, :tours, :direction_notes,
                    :meta_description, :parking_address,
                    :icon_color, :map_icon
                ]
            )
      end

      # Use callbacks to share common setup or constraints between actions.

      def set_tour
        @tour = Tour.find(params[:tour_id])
      end

      def set_record
        @record = Stop.find(params[:id])
      end

      def set_tour_stop
        @record = @tour.stops.find_by!(id: params[:id]) if @tour
      end

      def allowed?
        @allowed = current_user&.current_tenant_admin? || current_user.tours&.any? { |tour| Tour.all.include?(tour) }
      end
end
