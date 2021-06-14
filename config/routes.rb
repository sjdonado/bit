# frozen_string_literal: true

Rails.application.routes.draw do
  root 'sessions#welcome'

  get '/:slug', to: 'links#redirect', as: :short

  post 'login', to: 'sessions#create', as: :login
  post 'logout', to: 'sessions#destroy', as: :logout

  resources :links, only: %i[create]
  resources :users, only: %i[create]
end
