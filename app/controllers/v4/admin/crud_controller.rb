module V4
  module Admin
    class CrudController < V4Controller
      after_action :update_index

      def create
        head :unauthorized and return unless crud_allowed?

        model = params[:model].camelize.constantize
        @record = model.new(allowed_params)

        if @record.save
          render json: @record.search_data, status: :created and return
        else
          render json: serialize_errors, status: :unprocessable_entity
        end
      end

      def update
        head :unauthorized and return unless crud_allowed?
        set_record
        if @record.update(update_params)
          @record.reload
          render json: @record.search_data, status: :ok
        else
          render json: serialize_errors, status: :unprocessable_entity
        end
      end

      def destroy
        head :unauthorized and return unless crud_allowed?

        if @record.destroy
          head :no_content and return
        else
          render json: serialize_errors, status: :unprocessable_entity
        end
      end

      private

      def set_record
        id = params[:id]
        model = params[:model].camelize.constantize
        @record = model.find(id)
        set_related_record if params[:related_model]
      end

      def set_related_record
        related_model = params[:related_model].camelize.constantize
        @related_record = related_model.find(params[:value].to_i)
      end

      def update_index
        if params[:reindex] && params[:model] == "tour"
          Tour.find(params[:reindex][:id]).reindex
        else
          @record.reindex if @record.respond_to?(:reindex)
          @record.tours.each(&:reindex) if @record.respond_to?(:tours)
          @record.tour&.reindex if @record.respond_to?(:tour)
        end
        sleep 1
      end

      def update_params
        if @related_record
          { params[:attribute].to_sym => @related_record }
        else
          allowed_params
        end
      end

      def allowed_params
        case params[:model]
        when "medium"
          params.require(:medium).permit(:file, :filename, :embed, :video_provider, :video)
        when "tour_medium"
          params.require(:tour_medium).permit(:medium_id, :tour_id, :position)
        when "stop_medium"
          params.require(:stop_medium).permit(:medium_id, :stop_id, :position)
        when "map_overlay"
          params.require(:map_overlay).permit(:file, :filename, :south, :east, :north, :west)
        when "map_icon"
          params.require(:map_icon).permit(:file, :filename)
        when "flat_page"
          params.require(:flat_page).permit(:title, :body)
        when "tour_flat_page"
          params.require(:tour_flat_page).permit(:tour_id, :flat_page_id, :position)
        when "stop"
          default_location
          params.require(:stop).permit(:title, :lat, :lng, :address, :article_link, :description, :direction_intro, :direction_notes, :icon_color, :meta_description, :parking_lat, :parking_lng)
        when "tour_stop"
          params.require(:tour_stop).permit(:tour_id, :stop_id, :position)
        when "tour_mode"
          params.require(:tour_mode).permit(:tour_id, :mode_id)
        when "tour"
          params.require(:tour).permit(:title, :published, :default_lng, :map_type, :description, :meta_description, :link_address, :link_text, :is_geo, :restrict_bounds, :restrict_bounds_to_overlay, :use_directions, :blank_map)
        when "tour_set"
          params.require(:tour_set).permit(:name, :logo)
        end
      end

      def default_location
        return unless params[:stop][:lng].nil? || params[:stop][:lng].nil?

        location = Geocoder.search(request.remote_ip).first
        params[:stop][:lat] = location.latitude.to_f
        params[:stop][:lng] = location.longitude.to_f
      end
    end
  end
end
