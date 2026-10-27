# frozen_string_literal: true

module V4
  module Admin
    class UsersController < V4Controller
      def index
        head(:unauthorized) and return unless current_user&.super

        tours = tours_by_user
        users = User.all.map { |user| user.preview_data.merge(authored_tours: tours[user.id] || []) }
        render_json(users.sort_by { |u| u[:email] }) and return
      end

      # The signed-in user deleting their own account.
      def destroy_me
        head(:unauthorized) and return unless current_user&.persisted?

        if current_user.last_super?
          render(json: { error: "You're the only super user, so your account can't be deleted." }, status: :unprocessable_entity)
          return
        end

        current_user.delete_account!
        cookies.delete(:auth)
        head(:no_content)
      end

      def show
        render(json: User.new.search_data, status: :unauthorized) and return if current_user.id.nil?

        render(json: @record, status: :ok) and return
      end

      private

      # Each user's tours, grouped by site, from one pass through each site's
      # schema rather than one per user.
      def tours_by_user
        current = Apartment::Tenant.current
        by_user = Hash.new { |hash, id| hash[id] = [] }
        TourSet.find_each do |tour_set|
          begin
            Apartment::Tenant.switch!(tour_set.subdir)
          rescue Apartment::TenantNotFound
            next
          end
          TourAuthor.includes(:tour).group_by(&:user_id).each do |user_id, authorships|
            by_user[user_id] << {
              site: tour_set.name,
              subdir: tour_set.subdir,
              tours: authorships.filter_map do |authorship|
                { id: authorship.tour.id, title: authorship.tour.title, student: authorship.student } if authorship.tour
              end.sort_by { |tour| tour[:title].to_s.downcase },
            }
          end
        end
        by_user
      ensure
        Apartment::Tenant.switch!(current)
      end

      def set_record
        return unless current_user.id

        @record = current_user.search_data
      end
    end
  end
end
