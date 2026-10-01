# frozen_string_literal: true

module V4
  module Admin
    class ServicesController < V4Controller
      def url_resolver
        render(json: { error: 'you must provide a URL' }, status: :unprocessable_entity) and return unless params[:url]

        resolved_url = UrlResolver.resolve(params[:url])
        render(json: { error: 'could not resolve url' }, status: :unprocessable_entity) and return unless resolved_url

        render(json: { resolved_url: }, status: :ok)
      end
    end
  end
end
