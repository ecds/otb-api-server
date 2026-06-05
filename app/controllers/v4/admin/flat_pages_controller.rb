# frozen_string_literal: true

module V4
  module Admin
    class FlatPagesController < V4Controller
      def index
        head(:unauthorized) and return unless crud_allowed?

        @records = FlatPage.page(params[:page] || 1).per(params[:per] || FlatPage.count)
        @records = @records.where.not(id: params[:exclude].split(',').map(&:to_i)) if params[:exclude]
        set_pagination_header
        render(json: @records.map(&:search_data).sort_by { |flat_page| flat_page[:title] })
      end
    end
  end
end
