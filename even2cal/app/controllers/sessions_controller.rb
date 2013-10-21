class SessionsController < ApplicationController
  require 'google/api_client'
  require 'json'
  require 'date'

  def index
    @vk_authorized = vk_authorized
    @google_authorized = google_authorized
    @calendars = get_calendar_list(session[:google][:token]) if @google_authorized
		@event_pairs = JSON.parse(session[:vkontakte][:events]).reverse.to_a if @google_authorized && @vk_authorized
    @activePage = flash[:page] ? flash[:page] : 0
  end

  def vk_auth
    session[:vkontakte] = {
      token: auth_hash['credentials']['token'],
      events: get_vk_user_events(auth_hash['credentials']['token'])
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
    if vk_authorized
			import_events_to_calendar(session[:google][:calendar_id], params[:selected_events])
	    flash[:success] = "Выбранные события были импортированы! А теперь проверьте свой календарь." 
			redirect_to root_path		
		else
	    flash[:danger] = "Пожалуйста, сперва авторизуйтесь в Вконтакте." 
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

  def import_events_to_calendar(calendar_id, selected_events_array)
    client = Google::APIClient.new(
      :application_name => "Even2Cal",
      :application_version => "0.1")
    client.authorization.access_token = session[:google][:token]
    service = client.discovered_api('calendar', 'v3')  

    vk_events = JSON.parse(session[:vkontakte][:events]).select do |event|
      selected_events_array.include?(event["gid"].to_s)
		end

    vk_events.each do |event|
      client.execute(
        api_method: service.events.insert,
        parameters: {'calendarId' => calendar_id},
        body: prepare_params_from_event(event),
        headers: {'Content-Type' => 'application/json'}
      )
    end
  end

  def prepare_params_from_event(event)
		# TIMEZONE STILL HARDCODED
		# CHECK more easy way of time converting
    result = {
      'summary' => event["name"],
      'description' => ActionView::Base.full_sanitizer.sanitize(event["description"]),
      'start' => {
        'dateTime' => DateTime.parse(Time.at(event["start_date"].to_i).to_s).rfc3339,
        'timeZone' => 'Europe/Minsk' 
      },
      'end' => {
        'dateTime' => DateTime.parse(Time.at(event["start_date"].to_i + 1800).to_s).rfc3339,
        'timeZone' => 'Europe/Minsk'
      },
      'location' => get_event_location(event)
    }
    
    JSON.dump(result)
  end

  def get_event_location(event)
		if event["place"]
      @vk = VkontakteApi::Client.new(session[:vkontakte][:token])
      country = @vk.places.getCountryById(:cids => [event["place"]["country"]]).first["name"] if event["place"]["country"]
      city = @vk.places.getCityById(:cids => [event["place"]["city"]]).first["name"] if event["place"]["city"]
      address = event["place"]["address"] if event["place"]["address"]
      "#{address}, #{city}, #{country}"
		else
		  ""
		end
  end

  def get_calendar_list(auth_token)
    client = Google::APIClient.new(
      :application_name => "Even2Cal",
      :application_version => "0.1")
    client.authorization.access_token = auth_token

    service = client.discovered_api('calendar', 'v3')

    calendar_list = client.execute(
      :api_method => service.calendar_list.list,
      :parameters => {},
      :headers => {'Content-Type' => 'application/json'})
    calendar_list.data.items.collect {|cal| [cal.summary, cal.id]}
  end

  def get_vk_user_events(auth_token)
#   DO NOT FORGET TO REMOVE COUNTER LIMITS
    @vk = VkontakteApi::Client.new(auth_token)
    group_fields = ['place', 'description', 'start_date', 'end_date']

    all_groups = @vk.groups.get(extended: 1,
                                  fields: group_fields,
															    count: 30)
    all_groups.shift
    publics = @vk.groups.get(extended: 1,
                               filter: ['publics'],
                               fields: group_fields,
														   count: 10)
    publics.shift
    simple_groups = @vk.groups.get(extended: 1,
                                     filter: ['groups'],
                                     fields: group_fields,
																		 count: 10)
    simple_groups.shift
    
    events = all_groups - publics - simple_groups
    events.select! {|event| Time.at(event["start_date"].to_i) > Time.now}.to_json
  end

  def auth_hash
    request.env['omniauth.auth']
  end
end
