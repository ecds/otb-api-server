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
        if !@records.first.published_tours.empty? || current_user&.tour_sets.include?(@records.first) || current_user&.super
          render json: @records
        else
          render json: TourSet.none
        end
        return
      elsif current_user&.tour_sets.present? && !current_user.super
        @records = published.concat(current_user.tour_sets).uniq
      else
        @records = TourSet.all
      end

      if current_user.tour_sets.present? || current_user.super
        render json: @records, include: [ 'admins' ]
      else
        if current_user&.tour_sets.empty?
          @records = published
        end
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
        current_user&.current_tenant_admin? || @record.published_tours.present? || current_user.tour_sets.include?(@record)
      end
    end

    def crud_allowed?
      current_user&.super
    end

    def published
      TourSet.all.reject { |tour_set| tour_set.published_tours.empty? }
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
