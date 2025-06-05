# frozen_string_literal: true

Rails.application.routes.draw do
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # Opportunities API (index, create, apply)
  resources :opportunities, only: [:index]
end
