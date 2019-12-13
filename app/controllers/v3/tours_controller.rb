# frozen_string_literal: true

# app/controllers/v3/tours_controller.rb
# module V3
class V3::ToursController < V3Controller
  before_action :set_tour, only: [:show, :update, :destroy]
  authorize_resource

  # GET /tours
  def index
    @tours = if (params[:slug])
      tour_by_slug(params[:slug])
    elsif (current_user.current_tenant_admin?)
      Tour.all
    elsif (current_user.id)
      current_user.tours
    else
      Tour.published
    end
    if @tours.nil?
      render json: { error: '404: Tour not found' }, status: :not_found
    else
      render json: @tours,
              include: [
                'tour_stops',
                'stops',
                'stops.media',
                'stops.stop_media',
                'mode',
                'modes',
                'theme',
                'media',
                'tour_media',
                'flat_pages',
                'tour_flat_pages'
              ]
    end
  end

  # GET /tours/1
  def show
    render json: @tour,
           include: [
               'tour_stops',
               'stops',
               'stops.media',
               'stops.stop_media',
               'mode',
               'modes',
               'theme',
               'media',
               'tour_media',
               'flat_pages',
               'tour_flat_pages'
           ]
  end

  # POST /tours
  def create
    @tour = Tour.new(tour_params)
    if @tour.save
      response = render json: @tour, status: :created, location: "/#{Apartment::Tenant.current}/tours/#{@tour.id}"
      return response
    else
      render json: @tour.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /tours/1
  def update
    if @tour.update(tour_params)
      render json: @tour, location: "/#{Apartment::Tenant.current}/tours/#{@tour.id}"
    else
      render json: @tour.errors, status: :unprocessable_entity
    end
  end

  # DELETE /tours/1
  def destroy
    @tour.destroy
  end

    private

      # Use callbacks to share common setup or constraints between actions.
      def set_tour
        @tour = Tour.includes(:tour_stops).find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def tour_params
        ActiveModelSerializers::Deserialization
            .jsonapi_parse(
              params, only: [
                    :title, :description,
                    :is_geo, :modes, :published, :theme_id,
                    :mode, :meta_description, :stops,
                    :media, :authors, :flat_pages, :map_type,
                    :theme
                ]
            )
      end

      def tour_by_slug(slug)
        tour = Slug.find_by(slug: params[:slug]).tour
        if tour.published || current_user.current_tenant_admin? || current_user.tours.include?(tour)
          tour
        else
          nil
        end
      end
end

# TourSet.all.each do |ts|
#   Apartment::Tenant.switch! ts.subdir
#   default = Theme.find(1)
#   default.title = 'default'
#   default.save
#   old = Theme.where.not(id: 1)
#   old.each { |o| o.delete }
#   ActiveRecord::Base.connection.reset_pk_sequence!('themes')
#   themes = ["blue", "atl", "red", "dark-blue", "purple", "green", "orange", "dark-green", "austrian", "emory", "gsu", "gatech", "uga", "ksu"]
#   themes.each { |t| Theme.create(title: t)}
# end
  
# TourSet.all.each do |ts|
#   Apartment::Tenant.switch! ts.subdir
#   Tour.all.each do |t|
#     t.theme = Theme.find(1)
#     t.save
#   end
# end