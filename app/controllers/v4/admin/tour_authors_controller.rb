# frozen_string_literal: true

module V4
  module Admin
    class TourAuthorsController < V4Controller
      def index
        head(:unauthorized) and return unless authorized?

        @records = TourAuthor.where(tour_id: params[:tour_id])

        render(json: [].to_json, status: :ok) and return if @records.empty?

        render_json(@records.map { |author| author_data(author.user, author.student) }.sort_by { |a| a[:display_name].to_s.downcase }, status: :ok)
      end

      # People who could be added to the tour: authors of the site's other
      # tours, or for super users, anyone. Newcomers ask through an access
      # request instead.
      def candidates
        head(:unauthorized) and return unless authorized?

        current_ids = TourAuthor.where(tour_id: params[:tour_id]).select(:user_id)
        users = if current_user.super
          User.where.not(id: current_ids)
        else
          User.where(id: TourAuthor.where.not(user_id: current_ids).select(:user_id))
        end
        render_json(users.map { |user| author_data(user) }.sort_by { |a| a[:display_name].to_s.downcase })
      end

      # Only `student` can change.
      def update
        head(:unauthorized) and return unless authorized?
        head(:not_found) and return if @record.nil?

        if @record.update(student: ActiveModel::Type::Boolean.new.cast(params[:student]) || false)
          render_json(author_data(@record.user, @record.student))
        else
          render(json: serialize_errors, status: :unprocessable_entity)
        end
      end

      def create
        head(:unauthorized) and return unless authorized?

        @record = if params[:username]
          TourAuthor.new(user: User.find_by(display_name: params[:username]), tour_id: params[:tour_id])
        else
          TourAuthor.new(user_id: params[:user_id], tour_id: params[:tour_id])
        end
        @record.student = ActiveModel::Type::Boolean.new.cast(params[:student]) || false

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

      # `id` in the path is the user's id.
      def set_record
        @record = TourAuthor.find_by(tour_id: params[:tour_id], user_id: params[:user_id] || params[:id])
      end

      def author_data(user, student = false)
        { id: user.id, display_name: user.display_name, email: user.email, student: }
      end

      def authorized?
        current_user&.super || current_user&.current_tenant_admin?
      end
    end
  end
end
