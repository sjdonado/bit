# frozen_string_literal: true

class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.create(user_params)
    if @user.errors.any?
      render json: @user.errors, status: :unprocessable_entity
    else
      session[:user_id] = @user.id
      redirect_to '/'
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :password)
  end
end
