Rails.application.config.middleware.use OmniAuth::Builder do
  provider :vkontakte, ENV['API_KEY'], ENV['API_SECRET'],
    :scope => 'groups', :display => 'page'
  provider :google_oauth2, ENV["GOOGLE_KEY"], ENV["GOOGLE_SECRET"],
    :scope => ['calendar', 'userinfo.profile', 'userinfo.email'], :prompt => 'consent', :name => 'google'  

  OmniAuth.config.on_failure = Proc.new { |env|
    OmniAuth::FailureEndpoint.new(env).redirect_to_failure
  }
end

