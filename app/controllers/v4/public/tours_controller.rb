module V4
  module Public
    class ToursController < V4Controller
      def index
        @records = if current_user&.current_tenant_admin?
          Array(Tour.search("*", load: false, limit: Tour.count)) if current_user&.current_tenant_admin?
        elsif current_user
          user_tours = current_user.tours.map { |t| Tour.search("*", load: false, limit: 1).where(id: t.id, published: false).first }.flatten.compact if current_user
          published_tours = Array(Tour.search("*", load: false, limit: Tour.published.count).where(published: true))
          [ *published_tours, *user_tours ]
        else
            Array(Tour.search("*", load: false, limit: Tour.published.count).where(published: true))
        end

        render json: { title: "...." } and return if @records.nil?
        render json: {} and return if @records.empty?
        render json: @records
      end

      def show
        render json: @record, status: :ok and return if @record.published || crud_allowed?(@record)
        render json: { errors: [ "Not found" ] }, status: :not_found and return
      end

      def create
        raise NotImplementedError, "Create is not implemented in V4 Public"
      end

      def update
        raise NotImplementedError, "Update is not implemented in V4 Public"
      end

      def destroy
        raise NotImplementedError, "Destroy is not implemented in V4 Public"
      end

      def crud_allowed?(record = @record)
        tour = Tour.find(Integer(record.id)) unless record.nil?
        current_user&.current_tenant_admin? || current_user.tours.include?(tour)
      end

      def set_record
        @record = Tour.search("*", where: { slugs: params[:slug] }, limit: 1, load: false).first
      end
    end
  end
end
