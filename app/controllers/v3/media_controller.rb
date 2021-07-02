# frozen_string_literal: true

# app/controllers/v3/media_controller.rb
module V3
  class MediaController < V3Controller
    before_action :set_record, only: [:show, :update, :destroy, :file]

    # GET /media
    def index
      # TODO: This ins not ideal, we use these `not_in_*` scopes to make the list of media avaliable to add
      # to a stop or tour. But the paramerter does not make sense when just looking at it. Needs clearer language.
      @media = if params[:stop_id]
        Medium.not_in_stop(params[:stop_id]).or(Medium.no_stops)
      elsif params[:tour_id]
        Medium.not_in_tour(params[:tour_id]).or(Medium.no_tours)
      else
        Medium.all
      end
      render json: @media
    end

    # GET /media/1
    def show
      if @record.published || current_user.id.present?
        render json: @record
      else
        head 401
      end
    end

    # POST /media
    def create
      @record = Medium.new(record_params)

      if @record.save
        render json: @record, status: :created, location: "/#{Apartment::Tenant.current}/media/#{@record.id}"
      else
        render json: serialize_errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /media/1
    def update
      if @record.update(record_params)
        render json: @record
      else
        render json: serialize_errors, status: :unprocessable_entity
      end
    end

    # DELETE /media/1
    def destroy
      @record.destroy
    end

    def file
      if @record&.file&.attached?
        if params[:context] == 'mobile'
          redirect_to Rails.application.routes.url_helpers.rails_representation_url(@record.file.variant(resize: '300x300').processed, only_path: true)
        elsif params[:context] == 'tablet'
          redirect_to Rails.application.routes.url_helpers.rails_representation_url(@record.file.variant(resize: '400x400').processed, only_path: true)
        elsif params[:context] == 'desktop'
          redirect_to Rails.application.routes.url_helpers.rails_representation_url(@record.file.variant(resize: '750x750').processed, only_path: true)
        else
          redirect_to rails_blob_url(@record.file)
        end
      else
        head :not_found
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
              :title, :caption, :original_image, :stops, :tours, :video, :stop_id, :tour_id, :base_sixty_four, :video_provider, :embed
          ]
      )
    end
  end
end
