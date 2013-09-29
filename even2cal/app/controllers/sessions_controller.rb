class SessionsController < ApplicationController
  require 'google/api_client'

  def index
    @calendars = get_calendar_list(session[:google][:token]) if session[:google] 
  end
  
  def vk_auth
    session[:vkontakte] = {
      token: auth_hash['credentials']['token'],
      events: get_vk_user_events(auth_hash['credentials']['token'])}

    redirect_to root_path
  end

  def google_auth
    session[:google] = {token: auth_hash['credentials']['token']}

    redirect_to root_path
  end

  def import_events
    import_events_to_calendar(params[:calendar])
  end
 
  protected

  def import_events_to_calendar(calendar_id)
    client = Google::APIClient.new(
      :application_name => "Even2Cal",
      :application_version => "0.1")
    client.authorization.access_token = session[:google][:token]
    service = client.discovered_api('calendar', 'v3')  

    vk_events = session[:vkontakte][:events]
    vk_events.each do |event|
      client.execute(
        api_method: service.events.insert,
        parameters: prepare_params_from_event(event, calendar_id)
      )
    end
  end

  def get_calendar_list(auth_token)
    client = Google::APIClient.new(
      :application_name => "Even2Cal",
      :application_version => "0.1")
    client.authorization.access_token = auth_token
#    service = client.discovered_api('oauth2')
#    result = client.execute(
#      :api_method => service.userinfo.get,
#      :version => 'v3')
#    result.data.email.to_json

    service = client.discovered_api('calendar', 'v3')

    calendar_list = client.execute(
      :api_method => service.calendar_list.list,
      :parameters => {},
      :headers => {'Content-Type' => 'application/json'})
    calendar_list.data.items.collect {|cal| [cal.summary, cal.id]}
  end

  def get_vk_user_events(auth_token)
    @vk = VkontakteApi::Client.new(auth_token)
    group_fields = ['place', 'description', 'start_date', 'end_date']

    all_groups = @vk.groups.get(extended: 1, fields: group_fields, count: 20)
    all_groups.shift
    publics = @vk.groups.get(extended: 1, filter: ['publics'], fields: group_fields, count: 10)
    publics.shift
    simple_groups = @vk.groups.get(extended: 1, filter: ['groups'], fields: group_fields, count: 10)
    simple_groups.shift
    
    events = all_groups - publics - simple_groups
    events.to_json 
  end

  def auth_hash
    request.env['omniauth.auth']
  end
end
