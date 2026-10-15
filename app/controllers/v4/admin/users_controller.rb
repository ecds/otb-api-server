# frozen_string_literal: true

module V4
  module Admin
    class UsersController < V4Controller
      def index
        head(:unauthorized) and return unless current_user&.super

        render_json(User.all.map(&:preview_data).sort_by { |u| u[:email] }) and return
      end

      def show
        render(json: User.new.search_data, status: :unauthorized) and return if current_user.id.nil?

        render(json: @record, status: :ok) and return
      end

      private

      def set_record
        return unless current_user.id

        @record = current_user.search_data
      end
    end
  end
end
