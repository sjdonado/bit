# frozen_string_literal: true

class SessionsController < ApplicationController
  before_action :authenticate, except: %i[create]

  def create
    @user = User.find_by(username: session_params[:username])
    if @user&.authenticate(session_params[:password])
      session[:user_id] = @user.id
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

  def session_params
    params.permit(:username, :password)
  end
end
