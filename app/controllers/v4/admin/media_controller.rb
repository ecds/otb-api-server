# frozen_string_literal: true

module V4
  module Admin
    class MediaController < V4Controller
      def index
        head(:unauthorized) and return unless crud_allowed?

        @records = Medium.page(params[:page] || 1).per(params[:per] || Medium.count)
        @records = @records.where.not(id: params[:exclude].split(',').map(&:to_i)) if params[:exclude]
        set_pagination_header
        render(json: @records.map(&:search_data))
      end
    end
  end
end
