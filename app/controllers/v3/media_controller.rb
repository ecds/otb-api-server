# frozen_string_literal: true

# app/controllers/v3/media_controller.rb
module V3
  class MediaController < V3Controller
    # include Pagy::Backend
    before_action :set_record, only: [:show, :update, :destroy, :file]

    # GET /media
    def index
      # TODO: This ins not ideal, we use these `not_in_*` scopes to make the list of media avaliable to add
      # to a stop or tour. But the paramerter does not make sense when just looking at it. Needs clearer language.
      @media = if (current_user && current_user.current_tenant_admin?)
        Medium.all
      else
        Medium.all.map { |medium| medium if medium.published }.compact
      end
      # pagy, @media = pagy(@media)
      # pagy_headers_merge(pagy)
      if params[:page].present?
        @media = @media.page params[:page]
        self.set_pagination_header
      end
      render json: @media
    end

    # GET /media/1
    def show
      if @record.published || current_user.id.present?
        render json: @record
      else
        render json: { data: { id: 0, type: 'media', attributes: { title: '....' } } }
      end
    end

    # POST /media
    def create
      if allowed?
        @record = Medium.new(record_params)

        if @record.save
          render json: @record, status: :created, location: "/#{Apartment::Tenant.current}/media/#{@record.id}"
        else
          render json: serialize_errors, status: :unprocessable_entity
        end
      else
        render json: {}, status: :unauthorized
      end
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_record
      @record = Medium.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def record_params
      ActiveModelSerializers::Deserialization
      .jsonapi_parse(
        params, only: [
            :title, :caption, :original_image, :stops, :tours, :video, :stop_id, :tour_id, :base_sixty_four, :video_provider, :embed, :filename
          ]
      )
    end

    private

    def set_pagination_header(name=:media, options = {})
      scope = instance_variable_get("@#{name}")
      request_params = request.query_parameters
      url_without_params = request.original_url.slice(0..(request.original_url.index("?")-1)) unless request_params.empty?
      url_without_params ||= request.original_url

      page = {}
      page[:first] = 1 if scope.total_pages > 1 && !scope.first_page?
      page[:last] = scope.total_pages  if scope.total_pages > 1 && !scope.last_page?
      page[:next] = scope.current_page + 1 unless scope.last_page?
      page[:prev] = scope.current_page - 1 unless scope.first_page?

      pagination_links = []
      page.each do |k, v|
        new_request_hash= request_params.merge({:page => v})
        pagination_links << "<#{url_without_params}?#{new_request_hash.to_param}>; rel=\"#{k}\""
      end
      headers["Link"] = pagination_links.join(", ")
    end
  end
end
