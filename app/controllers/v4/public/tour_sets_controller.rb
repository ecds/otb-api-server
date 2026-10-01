# frozen_string_literal: true

module V4
  module Public
    class TourSetsController < V4Controller
      def index
        render(json: tour_sets.sort_by { |ts| ts[:name] })
      end

      private

      def tour_sets
        if current_user.super
          TourSet.all
        elsif current_user.tour_sets.present?
          [*published_tour_sets, *current_user.tour_sets].uniq
        else
          published_tour_sets
        end.map do |ts|
          {
            name: ts.name,
            subdir: ts.subdir,
            mapable_tours: ts.mapable_tours,
            published_tours: ts.published_tours.empty? ? [] : ts.published_tours.sort_by { |t| t[:title] },
          }
        end
      end

      def published_tour_sets
        TourSet.all.select(&:should_index?)
      end
    end
  end
end
