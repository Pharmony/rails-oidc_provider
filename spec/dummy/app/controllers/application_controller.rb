# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  helper_method :current_user

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = User.find_by(id: session[:user_id])
  end

  def authenticate_user!
    return if current_user

    redirect_to "#{request.base_url}/signin"
  end

  def sign_out(*_args)
    session.delete(:user_id)
    @current_user = nil
  end
end
