# frozen_string_literal: true

module V4
  module Public
    class StopsController < V4Controller
      @model_class = Stop

      def index
        head(:unauthorized) and return unless crud_allowed?

        render(json: Stop.all.map(&:search_data))
      end

      def show
        render(json: { errors: ['Not found'] }, status: :not_found) and return if @record.nil?

        return head(:not_found) unless @record.published

        render(json: @record.search_data)
      end

      def set_record
        @record = StopSlug.find_by(slug: params[:slug])&.stop
      end
    end
  end
end
