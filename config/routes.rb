# frozen_string_literal: true

Rails.application.routes.draw do
  root 'sessions#index'

  get '/:slug', to: 'links#redirect', as: :short
  get 'links/:slug/counter', to: 'links#counter', as: :counter
  get 'session/logout', to: 'sessions#destroy', as: :logout

  post 'login', to: 'sessions#create', as: :login

  resources :links, only: %i[create]
  resources :users, only: %i[create]
end
