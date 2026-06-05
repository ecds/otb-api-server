# frozen_string_literal: true

module V4
  module Admin
    class ToursController < V4Controller
      def index
        if params[:all].present?
          render(
            json: Tour.all.map do |tour|
              { title: tour.title, slug: tour.slug, id: tour.id }
            end,
            status: :ok,
          ) and return
        end
        render(json: { error: 'unauthorized' }, status: :unauthorized) and return unless crud_allowed?

        @records = if current_user.current_tenant_admin?
          Tour.all
        else
          current_user.tours
        end

        render(json: [].to_json, status: :ok) and return if @records.empty?

        render(json: @records.sort_by(&:title), status: :ok)
      end

      def show
        render(json: { error: 'unauthorized' }, status: :unauthorized) and return unless crud_allowed?

        render(json: @record, status: :ok) and return unless @record.nil?

        head(:not_found)
      end

      private

      def set_record
        @record = Tour.search('*', load: false, limit: 1).where(id: params[:id]).first
      end
    end
  end
end
