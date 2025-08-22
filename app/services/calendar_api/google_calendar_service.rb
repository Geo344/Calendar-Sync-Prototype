class CalendarApi::GoogleCalendarService
  def initialize(service_account)
    # Ensure the service account belongs to the correct provider
    raise ArgumentError, "Invalid service account provider" unless service_account.provider == 'google_oauth2'

    @service_account = service_account
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = service_account.access_token
  end

  def fetch_events_in_range(start_time, end_time)
    all_events = {}
    # Get all calendars
    calendars = @service.list_calendar_lists.items

    # Loop through each calendar and get all events
    calendars.each do |calendar|
      events_for_calendar = []
      page_token = nil

      loop do
        response = @service.list_events(
          calendar.id,
          time_min: start_time.to_datetime.rfc3339,
          time_max: end_time.to_datetime.rfc3339,
          single_events: true,
          order_by: 'startTime',
          page_token: page_token
        )

        events_for_calendar.concat(response.items)

        page_token = response.next_page_token
        break unless page_token
      end
      all_events[calendar.id] = events_for_calendar
    end

    all_events

  rescue Google::Apis::AuthorizationError
    # Handle token expiration. You might want to refresh the token here.
    if refresh_access_token!(@service_account)
      retry 
    else
      Rails.logger.error("Failed to refresh token, cannot retry API call.")
      return []
    end
  rescue => e
    Rails.logger.error("Google Calendar API Error: #{e.message}")
    []
  end

  private

  def refresh_access_token!(service_account)
    # Use the googleauth gem to create a new token object
    creds = Google::Auth::UserRefreshCredentials.new(
      client_id: ENV['GOOGLE_CLIENT_ID'],
      client_secret: ENV['GOOGLE_CLIENT_SECRET'],
      scope: service_account.scopes, # The scopes that were originally requested
      refresh_token: service_account.refresh_token,
      access_token: service_account.access_token
    )

    # Call the refresh! method to get a new access token
    if creds.refresh!
      # Update the service account with the new token and expiration
      service_account.update!(
        access_token: creds.access_token,
        expires_at: creds.expires_at,
        # Note: Google's refresh tokens are long-lived and usually don't change.
        # You can still update it if creds.refresh_token is different.
      )

      # Update the service's authorization with the new token
      @service.authorization = creds.access_token
      Rails.logger.info("Successfully refreshed access token for Google service account #{service_account.id}.")
      return true
    else
      Rails.logger.error("Failed to refresh token for Google service account #{service_account.id}.")
      return false
    end
  end
end