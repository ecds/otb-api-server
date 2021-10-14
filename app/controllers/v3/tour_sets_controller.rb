# frozen_string_literal: true

# Controller class for Tour Sets
# app/controllers/v3/tour_sets.rb
module V3
  class TourSetsController < V3Controller
    # GET /tour_sets
    def index
      @records = []
      if params[:subdir] && params[:subdir] != 'public'
        @records = TourSet.where(subdir: params[:subdir])
      elsif current_user.id.present? && !current_user.super
        @records = current_user.tour_sets
      else
        @records = TourSet.all
      end

      if current_user.current_tenant_admin? || current_user.super
        render json: @records, include: [ 'admins' ]
      else
        @records = @records.reject { |ts| ts.published_tours.empty? }
        render json: @records
      end
    end

    # GET /tour_sets/1
    def show
      if @allowed
        render json: @record
      else
        render json: { data: { id: 0, type: 'tour_sets', attributes: { name: '....' } } }
      end
    end

    # POST /tour_sets
    def create
      if crud_allowed?
        @record = TourSet.new(record_params)

        if @record.save
          render json: @record, status: :created, location: "/#{Apartment::Tenant.current}/#{@record.id}"
        else
          render json: serialize_errors, status: :unprocessable_entity
        end
      else
        head 401
      end
    end

    # PATCH/PUT /tour_sets/1
    def update
      if crud_allowed?
        if @record.update(record_params)
          render json: @record
        else
          render json: serialize_errors, status: :unprocessable_entity
        end
      else
        head 401
      end
    end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_record
      @record = TourSet.find(params[:id])
    end

    def allowed?
      set_record if @record.nil? && params[:id].present?
      @allowed = if @record.nil?
        crud_allowed?
      else
        current_user&.current_tenant_admin? || @record.published_tours.present?
      end
    end

    def crud_allowed?
      current_user&.super
    end

    # Only allow a trusted parameter "white list" through.
    def record_params
      ActiveModelSerializers::Deserialization
          .jsonapi_parse(
            params, only: [
                  :name, :tours, :admins, :base_sixty_four, :logo_title
              ]
          )
    end
  end
end
