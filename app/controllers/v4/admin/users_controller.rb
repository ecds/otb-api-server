module V4
  module Admin
    class UsersController < V4Controller
      def index
        begin
          head :unauthorized and return if current_user.nil? || current_user.id.nil?

          render json: current_user.search_data, status: :ok and return if params[:me]

          render json: User.all.map(&:search_data), status: :ok and return if current_user.current_tenant_admin?

          head :unauthorized
        rescue NoMethodError
          head :unauthorized and return
        end
      end
    end
  end
end
