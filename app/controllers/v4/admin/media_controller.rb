# frozen_string_literal: true

module V4
  module Admin
    class MediaController < V4Controller
      def index
        head(:unauthorized) and return unless crud_allowed?

        # Filtered before paginating, so pages and counts only cover matches.
        excluded = params[:exclude].to_s.split(',').map(&:to_i)
        records = Medium.includes({ file_attachment: :blob }, :tours, stops: :tours).order(created_at: :desc, id: :desc)
        records = records.where.not(id: excluded) if excluded.any?
        records = records.used_in_tour(params[:tour_id].to_i) if params[:tour_id].present?
        records = records.missing_alt_text if ActiveModel::Type::Boolean.new.cast(params[:missing_alt_text])
        records = records.unused if ActiveModel::Type::Boolean.new.cast(params[:unused])
        @records = records.page(params[:page] || 1).per(params[:per] || [Medium.count, 1].max)
        set_pagination_header
        # appears_in is only needed here, where the associations are preloaded.
        render_json(@records.map { |medium| medium.search_data.merge(appears_in: medium.appears_in) }.uniq.as_json, status: :ok) and return
      end

      # Deletes one medium and its file, but only while it isn't used
      # anywhere. Site admins only.
      def destroy
        head(:unauthorized) and return unless current_user&.current_tenant_admin?

        head(:not_found) and return unless @record

        unless Medium.unused.exists?(id: @record.id)
          render(json: { errors: ['This image is used in a tour or stop, so it can\'t be deleted.'] }, status: :conflict)
          return
        end

        @record.destroy
        head(:no_content)
      end

      # Deletes every medium in the site that isn't used anywhere, in the
      # background (each one's file is removed from storage too). Site admins
      # only, since it can't be undone.
      def destroy_unused
        head(:unauthorized) and return unless current_user&.current_tenant_admin?

        ids = Medium.unused.pluck(:id)
        DeleteUnusedMediaJob.perform_later(tenant: Apartment::Tenant.current, ids:) if ids.any?
        render(json: { deleting: ids.size }, status: :accepted)
      end

      private

      def set_record
        @record = Medium.find_by(id: params[:id])
      end
    end
  end
end
