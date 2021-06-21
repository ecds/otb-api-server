# frozen_string_literal: true

# app/controllers/v3/tours_controller.rb
# module V3
class V3::ToursController < V3Controller
  # GET /tours
  def index
    @records = if (params[:slug])
      tour = Slug.find_by(slug: params[:slug]).tour
      if tour.published || (current_user && current_user.current_tenant_admin?)
        tour
      else
        nil
      end
    elsif (current_user && current_user.current_tenant_admin?)
      Tour.all
    elsif (current_user && current_user.id)
      current_user.tours
    else
      Tour.published
    end

    if @records.nil?
      render json: { error: 'not found' }.to_json, status: 404
    else
      render json: @records, each_serializer: V3::TourBaseSerializer
    end
  end

  # GET /tours/1
  def show
    render json: @record
  end

  # POST /tours
  def create
    if current_user.current_tenant_admin?
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
    if @record.update(tour_params)
      render json: @record, location: "/#{Apartment::Tenant.current}/tours/#{@record.id}", include: [
        'tour_modes',
        'tour_stops',
        'stops',
        'stops.media',
        'stops.stop_media',
        'mode',
        'modes',
        'theme',
        'media',
        'tour_media',
        'flat_pages',
        'tour_flat_pages'
    ]
    else
      render json: serialize_errors, status: :unprocessable_entity
    end
  end

  # DELETE /tours/1
  def destroy
    @record.destroy
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
                    :media, :authors, :flat_pages, :map_type,
                    :theme, :use_directions, :default_lng
              ]
            )
      end

      def set_record
        @record = Tour.find(params[:id])
      end
end
