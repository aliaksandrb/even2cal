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
    Rails.logger.debug(@event_pairs)
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
    calendar_id = session[:google][:calendar_id]
    SocialNetworkConnector::Googler.import_events_to_calendar(calendar_id,
                                                              params[:selected_events],
                                                              session[:google][:calendars][calendar_id],
                                                              session[:google][:token],
                                                              session[:vkontakte][:token],
                                                              session[:vkontakte][:events])
  end

  def set_vk_session_events
    SocialNetworkConnector::Vkontakte.get_vk_user_events(auth_hash['credentials']['token'])
  end

  def set_calendars
    session[:google][:calendars] = {}
    calendars_with_timezones_array = SocialNetworkConnector::Googler.get_calendar_list(session[:google][:token])
    calendars_with_timezones_array.collect do |cal_array|
#     cal_array => [summary, id, timeZone]
#     Google notations for timezones: "Continent/Timezone". Example: "Europe/Minsk"
#     But Ruby uses only the part after '/'
      session[:google][:calendars][cal_array[1]] = /\A\w+\/(.*)/.match(cal_array[2])[1]
      [cal_array[0], cal_array[1]]
    end
  end

  def auth_hash
    request.env['omniauth.auth']
  end
end
