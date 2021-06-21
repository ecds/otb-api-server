# frozen_string_literal: true

# /app/controllers/v3/stops_controller.rb
# module V3
class V3::StopsController < V3Controller
  # GET /stops
  def index
    @records = if params[:tour_id]
      Stop.not_in_tour(params[:tour_id]).or(Stop.no_tours)
    elsif params[:slug]
      # stop = StopSlug.find_by(slug: params[:slug]).stop
      stop = Stop.by_slug_and_tour(params[:slug], params[:tour_id])
    else
      Stop.all
    end
    render json: @records,
    include: [
        'media',
        'stop_media'
    ]
  end

  # GET /stops/1
  def show
    render json: @record,
           include: [
               'media',
               'stop_media',
               'map_icon'
           ]
  end

  # POST /stops
  def create
    @record = Stop.new(stop_params)
    if @record.save
      render json: @record, status: :created, location: "/#{Apartment::Tenant.current}/#{@record.id}"
    else
      render json: serialize_errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /stops/1
  def update
    if @record.update(stop_params)
      render json: @record, location: "/#{Apartment::Tenant.current}/stops/#{@record.id}"
    else
      render json: serialize_errors, status: :unprocessable_entity
    end
  end

  # DELETE /stops/1
  def destroy
    @record.destroy
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
end
