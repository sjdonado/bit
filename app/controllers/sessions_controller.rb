# frozen_string_literal: true

class SessionsController < ApplicationController
  before_action :authenticate, except: %i[create]

  def create
    @user = User.find_by(username: session_params[:username])
    if @user&.authenticate(session_params[:password])
      session[:user_id] = @user.id
      redirect_to '/'
    else
      render json: nil, status: :unauthorized
    end
  end

  def destroy
    reset_session
    redirect_to '/'
  end

  private

  def session_params
    params.permit(:username, :password)
  end
end
