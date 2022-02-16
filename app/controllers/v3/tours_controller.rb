# frozen_string_literal: true

# app/controllers/v3/tours_controller.rb
module V3
  class ToursController < V3Controller
    # GET /tours
    def index
      @records = if (params[:slug])
        @record = Slug.find_by(slug: params[:slug]).tour
        if @record.published || crud_allowed?
          @record
        else
          nil
        end
      elsif (current_user && current_user.current_tenant_admin?)
        Tour.all
      elsif (current_user && current_user.id)
        (current_user.tours + Tour.published).uniq
      else
        Tour.published
      end
      if @records.nil?
        render json: { data: { id: 0, type: 'tours', attributes: { title: '....' } } }
      else
        render json: @records, each_serializer: V3::TourBaseSerializer
      end
    end

    # GET /tours/1
    def show
      request_loc = if request.env['ipinfo'].respond_to?('longitude')
        { centerLng: request.env['ipinfo'].longitude, centerLat: request.env['ipinfo'].latitude }
      else
        { centerLng: -84.38979, centerLat: 33.75432 }
      end

      if @record&.published || crud_allowed?
        render json: @record, loc: request_loc
      else
        render json: { data: { id: 0, type: 'tours', attributes: { title: '....' } } }
      end
    end

    # POST /tours
    def create
      if crud_allowed?
        @record = Tour.new(tour_params)
        if @record.save
          render json: @record, status: :created, location: "/#{Apartment::Tenant.current}/tours/#{@record.id}"
        else
          render json: serialize_errors, status: :unprocessable_entity
        end
      else
        head 401
      end
    end

    # PATCH/PUT /tours/1
    def update
      if crud_allowed?
        if @record.update(tour_params)
          render json: @record, location: "/#{Apartment::Tenant.current}/tours/#{@record.id}"
        else
          render json: serialize_errors, status: :unprocessable_entity
        end
      else
        head 401
      end
    end

      private
        # Only allow a trusted parameter "white list" through.
        def tour_params
          ActiveModelSerializers::Deserialization
              .jsonapi_parse(
                params, only: [
                      :title, :description,
                      :is_geo, :modes, :published, :theme_id,
                      :mode, :meta_description, :stops,
                      :media, :users, :flat_pages, :map_type,
                      :theme, :use_directions, :default_lng,
                      :link_address, :link_text, :restrict_bounds,
                      :restrict_bounds_to_overlay, :blank_map
                ]
              )
        end

        def set_record
          _record = Tour.find(params[:id])
          @record = _record&.published || @allowed ? _record : Tour.new(id: params[:id])
        end

        # def allowed?
        #   @allowed = crud_allowed? ||
        # end

        def crud_allowed?
          set_record if @record.nil? && params[:id].present?
          current_user&.current_tenant_admin? || current_user.tours.include?(@record)
        end
  end
end
