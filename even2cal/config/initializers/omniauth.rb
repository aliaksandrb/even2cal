Rails.application.config.middleware.use OmniAuth::Builder do
  provider :vkontakte, ENV['API_KEY'], ENV['API_SECRET'],
    :scope => 'groups', :display => 'page'
  provider :google_oauth2, ENV["GOOGLE_KEY"], ENV["GOOGLE_SECRET"],
    :scope => 'calendar', :prompt => 'consent', :name => 'google'  
end
