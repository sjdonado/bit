# frozen_string_literal: true

module SessionsHelper
  def authenticate
    @current_user = User.find_by(id: session[:user_id])
  end

  def logged_in?
    !@current_user.nil?
  end

  def current_user_username
    @current_user&.username
  end
end
