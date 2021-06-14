# frozen_string_literal: true

Rails.application.routes.draw do
  root 'links#index'

  get '/:slug', to: 'links#redirect', as: :short

  resources :links, only: %i[create]
  resources :users, only: %i[new create]
end
