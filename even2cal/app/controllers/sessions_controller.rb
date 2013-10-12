class SessionsController < ApplicationController
  require 'google/api_client'
  require 'json'
  require 'date'

  def index
			@vkontakte = false
      @google = true
      @calendars = get_calendar_list(session[:google][:token]) if google_authorized
  end

  def vk_auth
    session[:vkontakte] = {
      token: auth_hash['credentials']['token'],
      events: get_vk_user_events(auth_hash['credentials']['token'])}
    flash[:success] = "You have successfully logged in to VK" 
    redirect_to root_path
  end

  def google_auth
    session[:google] = {token: auth_hash['credentials']['token']}
    flash[:success] = "You have successfully logged in to Google" 
    redirect_to root_path 
  end

	def groups_listing
		@event_pairs = JSON.parse(session[:vkontakte][:events]).first(4).each_slice(2).to_a
		render :index 
	end

  def import_events
    if vk_authorized
			import_events_to_calendar(params[:calendar_id])
	    flash[:success] = "Events was imported! Check out your calendar now." 
			redirect_to root_path		
		else
	    flash[:danger] = "Please authorize VK first!" 
      redirect_to root_path		
		end
  end
 
  def failure
    flash[:danger] = "Authorization failed."
    redirect_to root_path
  end

  protected

  def import_events_to_calendar(calendar_id)
    client = Google::APIClient.new(
      :application_name => "Even2Cal",
      :application_version => "0.1")
    client.authorization.access_token = session[:google][:token]
    service = client.discovered_api('calendar', 'v3')  

    vk_events = JSON.parse(session[:vkontakte][:events]).first(4)
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
    @vk = VkontakteApi::Client.new(session[:vkontakte][:token])
    country = @vk.places.getCountryById(:cids => [event["place"]["country"]]).first["name"]
    city = @vk.places.getCityById(:cids => [event["place"]["city"]]).first["name"]
    address = event["place"]["address"]
    "#{address}, #{city}, #{country}"
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
