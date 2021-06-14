# frozen_string_literal: true

class UsersController < ApplicationController
  def create
    if user_params[:password] != params[:user][:confirm_password]
      return render json: { password: ['Password not match with Confirm Password'] }, status: :bad_request
    end

    @user = User.create(user_params)
    if @user.errors.any?
      render json: @user.errors, status: :unprocessable_entity
    else
      session[:user_id] = @user.id
      render json: nil, status: :ok
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :password)
  end
end
