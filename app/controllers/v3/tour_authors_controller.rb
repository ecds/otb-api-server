module V3
  class TourAuthorsController < ApplicationController
    before_action :set_tour_author, only: [:show]

    # GET /tour_authors
    def index
      if current_user&.current_tenant_admin?
        render json: TourAuthor.all
      else
        head 401
      end
    end

    # GET /tour_authors/1
    def show
      if current_user&.current_tenant_admin?
        render json: @tour_author
      else
        head 401
      end
    end

    # POST /tour_authors
    def create
      head 405
    end

    # PATCH/PUT /tour_set_admins/1
    def update
      head 405
    end

    # DELETE /tour_set_admins/1
    def destroy
      head 405
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_tour_author
        @tour_author = TourAuthor.find(params[:id])
      end
  end
end
