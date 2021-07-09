module V3
  class TourAuthorsController < ApplicationController
    before_action :set_tour_author, only: [:show, :update, :destroy]

    # GET /tour_authors
    def index
      @tour_authors = TourAuthor.all

      render json: @tour_authors
    end

    # GET /tour_authors/1
    def show
      render json: @tour_author
    end

    # POST /tour_authors
    def create
      @tour_author = TourAuthor.new(tour_author_params)

      if @tour_author.save
        render json: @tour_author, status: :created, location: "/#{Apartment::Tenant.current}/tours/#{@tour_author}"
      else
        render json: @tour_author.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /tour_authors/1
    def update
      if @tour_author.update(tour_author_params)
        render json: @tour_author
      else
        render json: @tour_author.errors, status: :unprocessable_entity
      end
    end

    # DELETE /tour_authors/1
    def destroy
      @tour_author.destroy
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_tour_author
        @tour_author = TourAuthor.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def tour_author_params
        ActiveModelSerializers::Deserialization
            .jsonapi_parse(
              params, only: [
                    :tour, :user
              ]
            )
      end
  end
end
