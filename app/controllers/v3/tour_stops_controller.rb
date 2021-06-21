# frozen_string_literal: true

# /app/controllers/v3/tour_stops_controller.rb
class V3::TourStopsController < V3Controller
  # GET /stops
  def index
    @records = if params[:tour_id] && params[:stop_id]
      TourStop.where(tour: Tour.find(params[:tour_id])).where(stop: Stop.find(params[:stop_id])).first || {}
    elsif params[:tour] && params[:slug]
      # stop = StopSlug.find_by(slug: params[:slug])
      stop = Stop.by_slug_and_tour(params[:slug], params[:tour]).first
      # TourStop.where(tour: Tour.find(params[:tour])).where(stop: stop).first
      TourStop.find_by(tour: Tour.find(params[:tour]), stop: stop)
    else
      TourStop.all
    end
    render json: @records, include: ['stop']
  end

  # GET /stops/1
  def show
    render json: @record, include: ['stop']
  end

  # POST /stops
  def create
    @record = TourStop.new(tour_stop_params)
    if @record.save
      render json: @record, status: :created, location: @record
    else
      render json: serialize_errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /stops/1
  def update
    if @record.update(tour_stop_params)
      # render json: @stop
      head :no_content
    else
      render json: serialize_errors, status: :unprocessable_entity
    end
  end

  # DELETE /stops/1
  def destroy
    if @record
      @record.destroy
    end
    head :no_content
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
end
