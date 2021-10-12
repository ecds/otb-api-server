# frozen_string_literal: true

# /app/controllers/v3/tour_relations_controller.rb
module V3
  class TourRelationsController < V3Controller

    def destroy
      head 405
    end

    def allowed?
      set_record if @record.nil? && params[:id].present?
      @allowed = @record&.published || crud_allowed?
    end

    def crud_allowed?
      current_user&.current_tenant_admin? ||
      current_user.tours&.any? { |tour| Tour.all.include?(tour) }
    end
  end
end
