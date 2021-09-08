# frozen_string_literal: true

#
# Endpoint that returns a tour serialized as GeoJSON
#
module V3
  class GeojsonToursController < ApplicationController
    def show
      @tour = Tour.find(params[:id])
      if @tour.published
        render json: { type: 'FeatureCollection', features: @tour.stops.map { |s| feature(s) } }.to_json
      else
        head 401
      end
    end

    private

      def feature(stop)
        stop.media.map { |m| m.caption = nil if m.caption.blank? }
        {
          type: 'Feature',
          geometry: {
              type: 'Point',
              coordinates: [stop.lng.to_f, stop.lat.to_f]
            },
            properties: {
              title: stop.title,
              description: stop.description,
              images: stop.media.map { |m| { caption: m.caption, url: "#{request.protocol}#{request.host}/#{m.desktop}" } }
            }
        }
      end
  end
end
