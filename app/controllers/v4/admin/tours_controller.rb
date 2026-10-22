# frozen_string_literal: true

module V4
  module Admin
    class ToursController < V4Controller
      before_action :set_tour_set, only: [:update]
      def index
        if params[:all].present?
          render_json(Tour.all.map { |tour| { title: tour.title, slug: tour.slug, id: tour.id } }) and return
        end
        render(json: { error: 'unauthorized' }, status: :unauthorized) and return unless crud_allowed?

        @records = if current_user.current_tenant_admin?
          Tour.all
        else
          current_user.tours
        end

        render(json: [].to_json, status: :ok) and return if @records.empty?

        render(json: @records.sort_by(&:title), status: :ok)
      end

      def show
        render(json: { error: 'unauthorized' }, status: :unauthorized) and return unless crud_allowed?

        render(json: @record.search_data, status: :ok) and return unless @record.nil?

        head(:not_found)
      end

      def create
        set_tour_set
        render(json: { error: 'unauthorized' }, status: :unauthorized) and return unless current_user&.current_tenant_tour_creator?

        @record = Tour.new(allowed_params)

        if @record.save
          current_user.tours << @record unless current_user.super || current_user.current_tenant_admin?
          render(json: @record.search_data, status: :created) and return
        else
          render(json: serialize_errors, status: :unprocessable_entity)
        end
      end

      # Tour document save (partial documents are fine). Responds from the database, not the
      # search index, so the client never gets back stale data.
      def update
        head(:not_found) and return if @record.nil?
        render(json: { error: 'unauthorized' }, status: :unauthorized) and return unless tour_editable?

        TourDocumentUpdate.call(@record, params.require(:tour).to_unsafe_h)
        render(json: Tour.search_import.find(@record.id).search_data, status: :ok)
      rescue TourDocumentUpdate::Invalid => e
        render(json: { errors: e.errors }, status: :unprocessable_entity)
      end

      # Read-only preview of the stops a tour gets from Open Geographies, with
      # anything a curator should check. ?refresh=true skips the short cache.
      def open_geographies
        @record = Tour.find_by(id: params[:id])
        head(:not_found) and return if @record.nil?
        render(json: { error: 'unauthorized' }, status: :unauthorized) and return unless tour_editable?

        preview = OpenGeographies::Source.new(@record.open_geographies_endpoint)
          .call(refresh: ActiveModel::Type::Boolean.new.cast(params[:refresh]))
        render_json(preview)
      rescue OpenGeographies::Source::Error => e
        render(json: { error: e.message }, status: :unprocessable_entity)
      end

      private

      def set_record
        # Read from the database (with everything search_data needs preloaded)
        # so a tour is available as soon as it's created or saved.
        @record = Tour.search_import.find_by(id: params[:id])
      end

      def tour_editable?
        return false unless current_user

        current_user.current_tenant_admin? || current_user.tours.include?(@record)
      end

      def allowed_params
        params.require(:tour).permit(
          :title,
          :published,
          :map_icon_id,
          :default_lng,
          :map_type,
          :description,
          :meta_description,
          :link_address,
          :link_text,
          :is_geo,
          :restrict_bounds,
          :restrict_bounds_to_overlay,
          :use_directions,
          :blank_map,
        )
      end
    end
  end
end
