Rails.application.config.middleware.use OmniAuth::Builder do

  provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'], {
    scope: 'email,profile,https://www.googleapis.com/auth/calendar.readonly',

    # Crucial for getting a refresh token for long-lived access
    access_type: 'offline',

    # Good for dev: ensures user sees consent screen every time,
    # which helps in re-obtaining refresh tokens if needed for testing.
    prompt: 'select_account consent',
    pkce: true
  }

  provider :microsoft_graph, ENV['AZURE_CLIENT_ID'], ENV['AZURE_CLIENT_SECRET'], {
    scope: 'email,openid,User.Read,Calendars.Read,offline_access',

    prompt: 'select_account',
    pkce: true
  }
  
  OmniAuth.config.allowed_request_methods = [:post]

  # Configure a global failure handler for OmniAuth
  OmniAuth.config.on_failure = Proc.new do |env|
    Rack::Response.new(['302 Moved'], 302, 'Location' => "/auth/failure?message=#{env['omniauth.error.type']}").finish
  end
end