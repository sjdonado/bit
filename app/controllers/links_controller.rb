# frozen_string_literal: true

class LinksController < ApplicationController
  before_action :authenticate, only: [:create]

  def redirect
    @link = Link.find_by_slug(params[:slug])

    if @link.nil?
      render file: "#{Rails.root}/public/404", status: :not_found
    else
      @link.update(click_counter: @link.click_counter + 1)
      redirect_to @link.url
    end
  end

  def counter
    @link = Link.find_by_slug(params[:slug])

    if @link
      render json: @link.click_counter
    else
      render json: nil, status: :not_found
    end
  end

  def create
    @link = Link.find_or_create_by(url: link_params[:url]) do |link|
      link.user = @current_user if @current_user
    end

    if @link.errors.any?
      render json: @link.errors, status: :unprocessable_entity
    else
      render partial: 'links/show', locals: { link: @link }, status: :ok
    end
  end

  private

  def link_params
    params.require(:link).permit(:url)
  end
end
