# frozen_string_literal: true

class SessionsController < ApplicationController
  before_action :authenticate, except: %i[create]
  before_action :set_user, only: %i[create]

  def create
    if @user&.authenticate(session_params[:password])
      session[:user_id] = @user.id
      session[:username] = @user.username
      render json: nil, status: :ok
    else
      render json: { username: ['Credentials not valid, try again or create an account'] }, status: :unauthorized
    end
  end

  def destroy
    reset_session
    render json: nil, status: :ok
  end

  private

  def set_user
    @user = User.find_by(username: session_params[:username])
  end

  def session_params
    params.permit(:username, :password)
  end
end
