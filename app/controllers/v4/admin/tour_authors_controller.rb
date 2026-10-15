# frozen_string_literal: true

module V4
  module Admin
    class TourAuthorsController < V4Controller
      def index
        head(:unauthorized) and return unless authorized?

        @records = TourAuthor.where(tour_id: params[:tour_id])

        render(json: [].to_json, status: :ok) and return if @records.empty?

        render(json: @records.map(&:user), status: :ok)
      end

      def create
        head(:unauthorized) and return unless authorized?

        @record = if params[:username]
          TourAuthor.new(user: User.find_by(display_name: params[:username]), tour_id: params[:tour_id])
        else
          TourAuthor.new(user_id: params[:user_id], tour_id: params[:tour_id])
        end

        if @record.save
          render(json: @record, status: :created) and return
        else
          render(json: serialize_errors, status: :unprocessable_entity)
        end
      end

      def destroy
        head(:unauthorized) and return unless authorized?
        head(:not_found) and return if @record.nil?

        if @record.delete
          head(:no_content) and return
        else
          render(json: serialize_errors, status: :unprocessable_entity)
        end
      end

      private

      def set_record
        @record = TourAuthor.find_by(tour_id: params[:tour_id], user_id: params[:user_id])
      end

      def authorized?
        current_user&.super || current_user&.current_tenant_admin?
      end
    end
  end
end
