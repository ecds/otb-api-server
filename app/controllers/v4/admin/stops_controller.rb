# frozen_string_literal: true

module V4
  module Admin
    class StopsController < V4Controller
      def index
        head(:unauthorized) and return unless crud_allowed?

        @records = Stop.page(params[:page] || 1).per(params[:per] || [Stop.count, 1].max)
        @records = @records.where.not(id: params[:exclude].split(',').map(&:to_i)) if params[:exclude]
        set_pagination_header
        render_json(@records.map(&:search_data).sort_by { |stop| stop[:title] })
      end
    end
  end
end
