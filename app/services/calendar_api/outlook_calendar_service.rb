class CalendarApi::OutlookCalendarService
  def initialize(service_account)
    raise ArgumentError, "Invalid service account provider" unless service_account.provider == 'microsoft_graph'

    @service_account = service_account
    @access_token = service_account.access_token
  end

  def fetch_events_in_range(start_time, end_time)
    
    client = Faraday.new(url: 'https://graph.microsoft.com') do |faraday|
      faraday.request :authorization, 'Bearer', @access_token
      faraday.response :json, content_type: /\bjson$/
    end

    start_date_time = start_time.to_datetime.iso8601
    end_date_time = end_time.to_datetime.iso8601
    
    begin
      response = client.get('v1.0/me/calendarview',
        startDateTime: start_date_time,
        endDateTime: end_date_time
      )

      Rails.logger.info("Outlook API response status: #{response.status}")
      if response.body['value'].nil?
        Rails.logger.info("Outlook API response body has no events.")
      else
        Rails.logger.info("Outlook API returned #{response.body['value'].count} events.")
      end

      response.body['value']
    rescue Faraday::ClientError => e
      # Handle specific HTTP errors, such as 401 Unauthorized for expired tokens.
      if e.response[:status] == 401
        if refresh_access_token!(@service_account)
          retry 
        else
          Rails.logger.error("Failed to refresh token, cannot retry API call.")
          return []
        end
      end
      Rails.logger.error("Microsoft Graph API Error: #{e.message}")
      []
    rescue => e
      Rails.logger.error("Microsoft Graph API Error: #{e.message}")
      []
    end
  end

  private

  def refresh_access_token!(service_account)
    # Ensure the refresh token and client credentials are available
    unless service_account.refresh_token.present?
      Rails.logger.error("No refresh token available for service account #{service_account.id}.")
      return false
    end

    # Configure the Faraday client to make a POST request
    conn = Faraday.new(
      url: 'https://login.microsoftonline.com/common/oauth2/v2.0/token',
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
    )

    # Make the POST request with the refresh token and client credentials
    response = conn.post do |req|
      req.body = {
        client_id: ENV['AZURE_CLIENT_ID'],
        client_secret: ENV['AZURE_CLIENT_SECRET'],
        refresh_token: service_account.refresh_token,
        grant_type: 'refresh_token'
      }
    end

    # Check if the token refresh was successful
    if response.success?
      token_data = JSON.parse(response.body)
      
      # Update the service account with the new token and expiration
      service_account.update!(
        access_token: token_data['access_token'],
        refresh_token: token_data['refresh_token'],
        expires_at: Time.current + token_data['expires_in']
      )
      # Update the instance variable so the subsequent API call uses the new token
      @access_token = token_data['access_token']
      Rails.logger.info("Successfully refreshed access token for service account #{service_account.id}.")
      return true
    else
      Rails.logger.error("Failed to refresh token for service account #{service_account.id}: #{response.body}")
      return false
    end
  end
end