# frozen_string_literal: true

require "sidekiq/web"

Rails.application.routes.draw do
  root "welcome#index"
  get "health" => "rails/health#show", as: :rails_health_check
  resources :tour_set_admins
  scope ":tenant", defaults: { format: :json } do
    scope module: :v3, constraints: ApiVersion.new("v3", true) do
      resources :tour_authors, path: "tour-authors"
      resources :users
      resources :modes, only: [ :index, :show ]
      resources :tour_sets, path: "tour-sets"
      resources :tour_set_admins, path: "tour-set-users"
      resources :tour_collections, path: "tour-collections"
      resources :tour_media, path: "tour-media"
      resources :map_overlays, path: "map-overlays"
      resources :map_icons, path: "map-icons"
      resources :themes
      resources :tours
      resources :media
      resources :stops
      resources :stop_media, path: "stop-media"
      resources :tour_media, path: "tour-media"
      resources :tour_modes, path: "tour-modes"
      resources :tour_stops, path: "tour-stops"
      resources :flat_pages, path: "flat-pages"
      resources :tour_flat_pages, path: "tour-flat-pages"
      resources :geojson_tours
    end
      namespace :v4 do
        namespace :public do
          resources :tours, only: [ :index ]
          resources :modes, only: [ :index ]
          resources :stops, only: [ :index ]
          resources :tour_sets, only: [ :index ], path: "tour-sets"
          get "tours/:slug", to: "tours#show"
          get "stops/:slug", to: "stops#show"
          get "media/:key", to: "media#show"
        end
        namespace :admin do
          resources :crud
          resources :access_requests
          resources :tours, only: [ :index, :show ]
          resources :flat_pages, only: [ :index ]
          resources :tour_sets, only: [ :index ]
          resources :media, only: [ :index ]
          resources :stops, only: [ :index ]
          resources :users, only: [ :index ]
          get "tour_sets/:slug", to: "tour_sets#show"
        end
      end
  end
  mount EcdsRailsAuthEngine::Engine, at: "/auth"
  mount Sidekiq::Web => "/sidekiq"
end
