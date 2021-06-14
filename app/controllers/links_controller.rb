# frozen_string_literal: true

class LinksController < ApplicationController
  def home
    render 'links/home'
  end

  def show
    @link = Link.find_by_slug(link_params[:slug])
    
    if @link.nil?
      render file: "#{Rails.root}/public/404", status: :not_found
    else
      @link.update(click_counter: @link.click_counter + 1)
      redirect_to @link.url
    end
  end

  def link_params
    params.permit(:slug)
  end
end
