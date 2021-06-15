# frozen_string_literal: true

class UsersController < ApplicationController
  around_action :confirm_password_validation, only: %i[create]

  def create
    @user = User.create(user_params)
    if @user.errors.any?
      render json: @user.errors, status: :unprocessable_entity
    else
      session[:user_id] = @user.id
      session[:username] = @user.username
      render json: nil, status: :ok
    end
  end

  private

  def confirm_password_validation
    if user_params[:password] == params[:user][:confirm_password]
      yield
    else
      render json: { password: ['Password not match with Confirm Password'] }, status: :bad_request
    end
  end

  def user_params
    params.require(:user).permit(:username, :password)
  end
end
