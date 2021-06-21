# frozen_string_literal: true

  class V3::TourCollectionsController < V3Controller
    # GET /v3/tour_collections
    def index
      @records = TourCollection.all

      render json: @records
    end

    # GET /v3/tour_collections/1
    def show
      render json: @record
    end

    # POST /v3/tour_collections
    def create
      @record = TourCollection.new(tour_collection_params)

      if @record.save
        render json: @record, status: :created, location: @record
      else
        render json: serialize_errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /v3/tour_collections/1
    def update
      if @record.update(tour_collection_params)
        render json: @record
      else
        render json: serialize_errors, status: :unprocessable_entity
      end
    end

    # DELETE /v3/tour_collections/1
    def destroy
      @record.destroy
    end

    private
      # Only allow a trusted parameter "white list" through.
      def tour_collection_params
        params.fetch(:tour_collection, {})
      end

      def set_record
        @record = TourCollection.find(params[:id])
      end
  end
