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
      elsif current_user.super
        @records = TourSet.all
      elsif current_user.id.present?
        @records = current_user.tour_sets
      else
        #TourSet.all.reject {|ts| p ts.tours.empty?}
        @records = TourSet.all.reject { |ts| ts.published_tours.empty? }
      end

      if current_user.current_tenant_admin? || current_user.super
        render json: @records, include: [ 'admins' ]
      else
        render json: @records
      end
    end

    # GET /tour_sets/1
    def show
      render json: @record
    end

    # POST /tour_sets
    def create
      @record = TourSet.new(record_params)

      if @record.save
        render json: @record, status: :created, location: "/#{Apartment::Tenant.current}/#{@record.id}"
      else
        render json: serialize_errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /tour_sets/1
    def update
      if record_params[:logo].nil? && @record.logo.attached?
        @record.logo.purge
        puts @record.logo.attached?
      end

      @record.logo = nil if record_params
      @record.base_sixty_four = nil if record_params[:base_sixty_four].nil?
      if @record.update(record_params)
        render json: @record
      else
        render json: serialize_errors, status: :unprocessable_entity
      end
    end

    # DELETE /tour_sets/1
    def destroy
      @record.destroy
    end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_record
      @record = TourSet.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def record_params
      ActiveModelSerializers::Deserialization
          .jsonapi_parse(
            params, only: [
                  :name, :tours, :admins, :base_sixty_four, :logo_title, :logo
              ]
          )
    end
  end
end
