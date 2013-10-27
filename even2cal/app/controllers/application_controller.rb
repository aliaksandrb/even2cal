class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  unless Rails.application.config.consider_all_requests_local
    rescue_from Exception, with: lambda { |exception| render_error 404, exception }

    rescue_from ActionController::RoutingError,
                ActionController::UnknownController,
                ::AbstractController::ActionNotFound,
                ActiveRecord::RecordNotFound,
                  with: lambda { |exception| render_error 404, exception }
  end

  private

  def google_authorized
    session[:google] && session[:google][:token]
  end

  def vk_authorized
    session[:vkontakte] && session[:vkontakte][:token]
  end

  def render_error(status, exception)
    redirect_to "errors/error_#{status}", status: status
  end
end
