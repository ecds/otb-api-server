module V4
  module Public
    class ToursController < V3::ToursController
      def index
        @records = if params[:slug]
          record = Tour.search(params[:slug], fields: [ :slug ], limit: 1, load: false).first
          record if record.published || crud_allowed?(record)
        elsif current_user&.current_tenant_admin?
          Array(Tour.search("*", load: false, limit: Tour.count)) if current_user&.current_tenant_admin?
        elsif current_user
          user_tours = current_user.tours.map { |t| Tour.search("*", load: false, limit: 1).where(id: t.id).first } if current_user
          (
            user_tours +
            Array(Tour.search("*", load: false, limit: Tour.published.count).where(published: true))
          ).uniq
        else
          Array(Tour.search("*", load: false, limit: Tour.published.count).where(published: true))
        end

        render json: { data: { title: "...." } } if @records.nil?
        render json: { data: @records } unless @records.nil?
      end

      def create
        raise NotImplementedError, "Create is not implemented in V4"
      end

      def update
        raise NotImplementedError, "Update is not implemented in V4"
      end

      def destroy
        raise NotImplementedError, "Destroy is not implemented in V4"
      end

      def crud_allowed?(record = @record)
        tour = Tour.find(Integer(record.id)) unless record.nil?
        current_user&.current_tenant_admin? || current_user.tours.include?(tour)
      end

      def set_record
        @record = Tour.search("*").where(id: params[:id]).limit(1).load(false).first
      end
    end
  end
end
