module V4
  module Public
    class ModesController < V4Controller
      def index
        render json: Mode.all.map(&:search_data)
      end
    end
  end
end
