class SessionsController < ApplicationController
  def index
    
  end
  
  def vk_auth
    group_list = get_vk_user_events(auth_hash['credentials']['token'])
    render :json => group_list
    #redirect_to root_path
  end

  def google_auth
    render :text => auth_hash.to_json
  end

  protected

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
