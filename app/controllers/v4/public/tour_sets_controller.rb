module V4
  module Public
    class TourSetsController < V4Controller
      def index
        render json: tour_sets.sort_by { |ts| ts[:name] }
      end

      private

      def tour_sets
        if current_user.super
          TourSet.all
        elsif current_user.tour_sets.present?
          [ *published_tour_sets, *current_user.tour_sets ].uniq
        else
          published_tour_sets
        end.map { |ts| { name: ts.name, subdir: ts.subdir } }
      end

      def published_tour_sets
        TourSet.all.select(&:should_index?)
      end
    end
  end
end
