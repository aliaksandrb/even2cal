module SocialNetworkConnector
  class Googler
    require 'google/api_client'
    require 'json'
    require 'date'

    class << self
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
        calendar_list.data.items.reject{ |cal|
          cal.accessRole != "writer" && cal.accessRole != "owner"
        }.collect{ |cal| [cal.summary, cal.id, cal.timeZone]}
      end

      def import_events_to_calendar(calendar_id, selected_events_array, calendar_timezone, google_token, vk_token, events)
        client = Google::APIClient.new(
          :application_name => "Even2Cal",
          :application_version => "0.1")
        client.authorization.access_token = google_token 
        service = client.discovered_api('calendar', 'v3')  
    
        vk_events = JSON.parse(events).select do |event|
          selected_events_array.include?(event["gid"].to_s)
    		end
    
        vk_events.each do |event|
          client.execute(
            api_method: service.events.insert,
            parameters: {'calendarId' => calendar_id},
                  body: prepare_params_from_event(event, vk_token, calendar_timezone), 
               headers: {'Content-Type' => 'application/json'}
          )
        end
      end

      protected

      def prepare_params_from_event(event, vk_token, calendar_timezone)
        current_timezone = Time.zone
        Time.zone = calendar_timezone
       	# CHECK more easy way of time converting
         result = {
           'summary' => event["name"],
           'description' => ActionView::Base.full_sanitizer.sanitize(event["description"]),
           'start' => {
             'dateTime' => DateTime.parse(Time.zone.at(event["start_date"].to_i).to_s).rfc3339
           },
           'end' => {
             'dateTime' => DateTime.parse(Time.zone.at(event["start_date"].to_i + 1800).to_s).rfc3339
           },
           'location' => SocialNetworkConnector::Vkontakte.get_event_location(event, vk_token)
         }
         
         Time.zone = current_timezone
         JSON.dump(result)
       end
    end
  end

  class Vkontakte
    class << self
      def get_vk_user_events(auth_token)
#       DO NOT FORGET TO REMOVE COUNTER LIMITS
        vk = VkontakteApi::Client.new(auth_token)
        group_fields = ['place', 'description', 'start_date', 'end_date']

        all_groups = vk.groups.get(extended: 1,
                                     fields: group_fields)
      													      #count: 60)
        all_groups.shift
        publics = vk.groups.get(extended: 1,
                                  filter: ['publics'],
                                  fields: group_fields)
      							#					     count: 20)
        publics.shift
        simple_groups = vk.groups.get(extended: 1,
                                        filter: ['groups'],
                                        fields: group_fields)
      							#							       count: 20)
        simple_groups.shift
        
#       VK has a bug in API - it's cannot just return groups with type 'event' 
        events = all_groups - publics - simple_groups
#       Add user Timezone here
        events.select! {|event| Time.at(event["start_date"].to_i) > Time.now}.to_json
      end

      def get_event_location(event, vk_token)
	      if event["place"]
          vk = VkontakteApi::Client.new(vk_token)
          country = vk.places.getCountryById(:cids => [event["place"]["country"]]).first["name"] if event["place"]["country"]
          city = vk.places.getCityById(:cids => [event["place"]["city"]]).first["name"] if event["place"]["city"]
          address = event["place"]["address"] if event["place"]["address"]
          "#{address}, #{city}, #{country}"
	    	else
	    	  ""
	    	end
      end
    end
  end
end
