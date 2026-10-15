# frozen_string_literal: true

module V4
  module Admin
    # Address lookups for placing stops. Proxied so the provider's usage
    # limits, identification, and any API key stay on the server.
    class GeocodeController < V4Controller
      before_action :authorize

      def search
        render_result(AddressGeocoder.search(params[:q]))
      end

      def reverse
        render_result(AddressGeocoder.reverse(params[:lat], params[:lng]))
      end

      private

      def authorize
        head(:unauthorized) unless current_user && crud_allowed?
      end

      # The geocoder gem logs provider errors and returns no results, so an
      # outage reads the same as a miss here.
      def render_result(result)
        if result
          render(json: result, status: :ok)
        else
          render(json: { error: 'No location found. Check the address and try again.' }, status: :not_found)
        end
      end
    end
  end
end
