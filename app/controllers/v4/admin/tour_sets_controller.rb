# frozen_string_literal: true

module V4
  module Admin
    class TourSetsController < V4Controller
      def index
        render(json: { error: 'unauthorized' }, status: :unauthorized) and return if current_user.id.nil?
        if current_user.id
          render(
            json: TourSet.all.sort_by(&:name).map do |ts|
              { name: ts.name, subdir: ts.subdir, id: ts.id }
            end,
            status: :ok,
          ) and return
        end

        render(json: current_user.tour_sets.sort_by(&:name), status: :ok)
      end

      def show
        render(json: { error: 'not found' }, status: :not_found) and return if @record.nil?
        if current_user.super || current_user.tour_sets.include?(@record)
          render(
            json: { **@record.admin_data, tours: all_tours },
            status: :ok,
          ) and return
        end
        head(:no_content) and return if current_user.all_tours.map { |t| t[:tenant] }.include?(@record.subdir)

        render(json: { error: 'unauthorized' }, status: :unauthorized)
      end

      private

      def set_record
        @record = TourSet.find_by(subdir: params[:slug])
      end

      def all_tours
        Apartment::Tenant.switch!(@record.subdir)
        Tour.order(:title).map { |tour| tour_summary(tour) }
      end

      def tour_summary(tour)
        { id: tour.id, title: tour.title, slug: tour.slug, published: tour.published }
      end

      def user_authorized?; end
    end
  end
end
