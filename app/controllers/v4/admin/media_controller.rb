# frozen_string_literal: true

module V4
  module Admin
    class MediaController < V4Controller
      def index
        head(:unauthorized) and return unless crud_allowed?

        # Filtered before paginating, so pages and counts only cover matches.
        excluded = params[:exclude].to_s.split(',').map(&:to_i)
        records = Medium.includes({ file_attachment: :blob }, :tours, stops: :tours).order(created_at: :desc, id: :desc)
        records = records.where.not(id: excluded) if excluded.any?
        records = records.used_in_tour(params[:tour_id].to_i) if params[:tour_id].present?
        @records = records.page(params[:page] || 1).per(params[:per] || [Medium.count, 1].max)
        set_pagination_header
        # appears_in is only needed here, where the associations are preloaded.
        render_json(@records.map { |medium| medium.search_data.merge(appears_in: medium.appears_in) }.uniq.as_json, status: :ok) and return
      end
    end
  end
end
