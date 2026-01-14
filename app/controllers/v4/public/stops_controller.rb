module V4
  module Public    
    class StopsController < V4Controller
      def index
        @records = if (params[:slug])
          Stop.search(params[:slug], fields: [:slug], load: false).first
        else
          Array(Stop.search('*', load: false))
        end
        render json: { data: @records }
      end
    end
  end
end