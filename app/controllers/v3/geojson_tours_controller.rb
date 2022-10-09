# frozen_string_literal: true

#
# Endpoint that returns a tour serialized as GeoJSON
#
module V3
  class GeojsonToursController < ApplicationController
    include ActionView::Helpers::SanitizeHelper

    def show
      @tour = Tour.find(params[:id])
      # if @tour.published
      geojosn = {
                  type: 'FeatureCollection',
                  crs: {
                    type: 'name',
                    properties: {
                      name: 'urn:ogc:def:crs:EPSG::4326'
                    }
                  },
                  meta: meta_content,
                  features: @tour.tour_stops.map { |tour_stop| feature(tour_stop.position, tour_stop.stop) }
                }
      render json: geojosn.to_json
      # render json: { type: 'FeatureCollection', meta: meta_content, features: @tour.tour_stops.map { |tour_stop| feature(tour_stop.position, tour_stop.stop) } }.to_json
      # else
      #   head 401
      # end
    end

    private

      def meta_content
        {
          title: @tour.title,
          intro: sanitize(@tour.description)
        }
      end

      def feature(position, stop)
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
            position: position,
            images: stop.media.map do |m|
              {
                caption: m.caption,
                full: m.files[:desktop],
                thumb: m.files[:mobile]
              }
            end
          }
        }
      end
  end
end
