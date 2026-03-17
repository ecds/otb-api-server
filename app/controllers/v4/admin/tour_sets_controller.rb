module V4
  module Admin
    class TourSetsController < V4Controller
      def index
        render json: { error: "unauthorized" }, status: :unauthorized and return unless current_user.id
        render json: TourSet.all.sort_by(&:name), status: :ok and return  if current_user.super
        render json: current_user.tour_sets.sort_by(&:name), status: :ok
      end

      def show
        render json: { error: "unauthorized" }, status: :unauthorized and return unless current_user.super || current_user.tour_sets.include?(@record)

        render json: @record.search_data, status: :ok and return unless @record.nil?

        head :not_found
      end

      private

      def set_record
        @record = TourSet.find_by(subdir: params[:slug])
      end
    end
  end
end
