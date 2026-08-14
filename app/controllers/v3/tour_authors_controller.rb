# frozen_string_literal: true

module V3
  class TourAuthorsController < ApplicationController
    before_action :set_tour_author, only: [:show]

    # GET /tour_authors
    def index
      if current_user&.current_tenant_admin?
        render(json: TourAuthor.all)
      else
        head(:unauthorized)
      end
    end

    # GET /tour_authors/1
    def show
      if current_user&.current_tenant_admin?
        render(json: @tour_author)
      else
        head(:unauthorized)
      end
    end

    # POST /tour_authors
    def create
      head(:method_not_allowed)
    end

    # PATCH/PUT /tour_set_admins/1
    def update
      head(:method_not_allowed)
    end

    # DELETE /tour_set_admins/1
    def destroy
      head(:method_not_allowed)
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_tour_author
      @tour_author = TourAuthor.find(params[:id])
    end
  end
end
