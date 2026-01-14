module V4
  module Public    
    class TourSetsController < V4Controller
      def index
        render json: { data: Array(TourSet.search('*', load: false, limit: TourSet.count)).sort_by(&:name) }
      end
    end
  end
end