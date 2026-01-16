module V4
  module Admin
    class CrudController < V4Controller
      def create
        head 401 unless crud_allowed?
      end

      def update
        head 401 unless crud_allowed?

        if @related_record
          if params[:related_type] == "belongs_to"
            @record.update(
              params[:attribute].to_sym => @related_record
            )
          end
        else
          @record.update(
            params[:attribute].to_sym => params[:value]
          )
        end
      end

      def set_record
        id = params[:id]
        model = params[:model].titleize.constantize
        @record = model.find(id)
        set_related_record if params[:related_model]
      end

      def set_related_record
        related_model = params[:related_model].titleize.constantize
        @related_record = related_model.find(params[:value].to_i)
      end
    end
  end
end
