Rails.application.routes.draw do
  mount GoodJob::Engine => "jobs"

  resource :registration
  resource :session
  resource :password_reset
  resource :password

  namespace :settings do
    resource :profile, only: %i[show update]
    resource :preferences, only: %i[show update]
    resource :notifications, only: %i[show update]
    resource :billing, only: %i[show update]
    resource :hosting, only: %i[show update]
  end

  resources :transactions do
    match "search" => "transactions#search", on: :collection, via: [ :get, :post ], as: :search
  end

  namespace :transactions do
    resources :categories
  end

  resources :accounts, shallow: true do
    post :sync, on: :member
    resources :valuations
  end

  # For managing self-hosted upgrades and release notifications
  resources :upgrades, only: [] do
    member do
      post :acknowledge
      post :deploy
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  root "pages#dashboard"
end
