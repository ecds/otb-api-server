module V4
  module Public
    class StopsController < V4Controller
      @model_class = Stop

      def index
          head :unauthorized and return unless crud_allowed?
          render json: { **Stop.all.map(&:search_data) }
      end

      def show
        render json: { errors: [ "Not found" ] }, status: :not_found and return if @record.nil?
        render json: @record.search_data if @record.published
      end

      def set_record
        @record = StopSlug.find_by(slugs: params[:slug])&.stop
      end
    end
  end
end
