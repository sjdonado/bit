# frozen_string_literal: true

module SessionsHelper
  def current_user_username
    session[:username]
  end
end
