# frozen_string_literal: true

module SessionsHelper
  def logged_in?
    !@current_user.nil?
  end

  def authenticate
    @current_user = User.find_by(id: session[:user_id])
  end
end
