class SessionsController < ApplicationController
  require 'social_network_connector'
  require 'json'

  def index
    @vk_authorized = vk_authorized
    @google_authorized = google_authorized
    @calendars = set_calendars if @google_authorized
    if @google_authorized && @vk_authorized && session[:google][:calendar_id]
		  @event_pairs = JSON.parse(session[:vkontakte][:events]).reverse.to_a 
    end
    @activePage = flash[:page] ? flash[:page] : 0
  end

  def vk_auth
    session[:vkontakte] = {
      token: auth_hash['credentials']['token'],
      events: set_vk_session_events 
    }
    flash[:page] = 2
    flash[:success] = "Вы успешно авторизовались в Вконтакте" 
    redirect_to root_path
  end

  def google_auth
    session[:google] = {token: auth_hash['credentials']['token']}
    flash[:page] = 3
    flash[:success] = "Вы успешно авторизовались в Google" 
    redirect_to root_path 
  end

	def select_calendar
    session[:google][:calendar_id] = params[:calendar_id]	
    flash[:page] = 4
		redirect_to root_path
	end

  def import_events
    if vk_authorized && google_authorized && !params[:selected_events].blank?
      do_import
	    flash[:success] = "Выбранные события были импортированы! А теперь проверьте свой календарь." 
			redirect_to root_path		
		else
	    flash[:danger] = "Пожалуйста, выберете события для импорта." 
      flash[:page] = 4
      redirect_to root_path		
		end
  end
 
  def failure
    flash[:danger] = "Проблемы с авторизацией!"
    redirect_to root_path
  end

  def logout
    reset_session
	  flash[:success] = "Сессия была удалена!"
    redirect_to root_path
  end

  protected

  def do_import
    SocialNetworkConnector::Googler.import_events_to_calendar(session[:google][:calendar_id],
                                                              params[:selected_events],
                                                              session[:google][:token],
                                                              session[:vkontakte][:token],
                                                              session[:vkontakte][:events])
  end

  def set_vk_session_events
    SocialNetworkConnector::Vkontakte.get_vk_user_events(auth_hash['credentials']['token'])
  end

  def set_calendars
    SocialNetworkConnector::Googler.get_calendar_list(session[:google][:token])
  end

  def auth_hash
    request.env['omniauth.auth']
  end
end
