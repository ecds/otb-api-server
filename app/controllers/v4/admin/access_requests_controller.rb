# frozen_string_literal: true

module V4
  module Admin
    class AccessRequestsController < V4Controller
      before_action :tenant_admin, except: [:create, :destroy]

      def index
        render_json(AccessRequest.where(tour_set:).map(&:search_data).uniq.as_json, status: :ok) and return
      end

      def update
        if @record.update(update_params)
          render(json: @record, status: :ok) and return
        else
          render(json: serialize_errors, status: :unprocessable_entity)
        end
      end

      def create
        head(:unauthorized) and return unless current_user.id

        @record = AccessRequest.new(create_params)
        if @record.save
          mailer = AccessRequestMailer.with(access_request: @record)
          mailer.access_request_email.deliver_later if params[:tour_ids].nil?
          mailer.access_request_tour_email.deliver_later if params[:tour_ids].present?
          render(json: @record, status: :created) and return
        else
          render(json: serialize_errors, status: :unprocessable_entity)
        end
      end

      def destroy
        head(:unauthorized) and return unless requester?

        if @record.delete
          head(:no_content) and return
        else
          render(json: serialize_errors, status: :unprocessable_entity)
        end
      end

      private

      def tenant_admin
        Apartment::Tenant.switch!(params[:tenant])
        begin
          head(:unauthorized) and return unless current_user&.super || current_user&.current_tenant_admin?
        rescue NoMethodError
          head(:unauthorized) and return
        end
      end

      def create_params
        {
          user: User.find(params[:user]),
          tour_set:,
          tour_ids: params[:tour_ids]&.map(&:to_i) || [],
        }
      end

      def update_params
        params.require(:access_request).permit(:approved, :tour_ids, tour_ids: [])
      end

      def set_record
        @record = AccessRequest.find(params[:id])
      end

      def requester?
        @record.user == current_user
      end

      def tour_set
        TourSet.find_by(subdir: params[:tenant])
      end
    end
  end
end
