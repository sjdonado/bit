# frozen_string_literal: true

Rails.application.routes.draw do
  get '/:slug', to: 'links#show', as: :short
end
