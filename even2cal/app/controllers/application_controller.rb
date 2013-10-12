class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  private

  def google_authorized
    session[:google] && session[:google][:token]
  end

  def vk_authorized
    session[:vkontakte] && session[:vkontakte][:token]
  end

end
