# frozen_string_literal: true

Rails.application.routes.draw do
  root 'links#home'

  get '/:slug', to: 'links#show', as: :short
end
