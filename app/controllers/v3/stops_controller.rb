# frozen_string_literal: true

# /app/controllers/v3/stops_controller.rb
# module V3
class V3::StopsController < V3::TourRelationsController
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

  # POST /stops
  def create
    if crud_allowed?
      @record = Stop.new(stop_params)
      if @record.save
        render json: @record, status: :created, location: "/#{Apartment::Tenant.current}/#{@record.id}"
      end
    else
      head 401
    end
  end

  # PATCH/PUT /stops/1
  def update
    if crud_allowed?
      if @record&.update(stop_params)
        render json: @record, location: "/#{Apartment::Tenant.current}/stops/#{@record.id}"
      end
    else
      head 401
    end
  end

  def destroy
    if !crud_allowed?
      head 401
    elsif crud_allowed? && @record.orphaned
      @record.destroy
    elsif crud_allowed? && !@record.orphaned
      head 405
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

      # Callbacks
      def set_record
        _record = Stop.find_by(id: params[:id])
        @record = _record&.published || @allowed ? _record : Stop.new(id: params[:id])
      end
end
