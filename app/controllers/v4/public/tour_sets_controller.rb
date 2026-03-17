module V4
  module Public
    class TourSetsController < V4Controller
      def index
        @records = TourSet.search("*", load: false, limit: TourSet.count)
        render json: Array(@records).sort_by(&:name)
      end
    end
  end
end
