class FetchCalendarEventsJob < ApplicationJob
  queue_as :default

  def perform(service_account_id)
    service_account = nil
    user = nil

    begin
      service_account = ServiceAccount.find(service_account_id)
      user = service_account.user

      # Status change as new job begins
      user.update(status: 'in_progress')
      
      three_years_ago = 3.years.ago
      six_months_from_now = 6.months.from_now

      events = []

      if service_account.provider == 'google_oauth2'
        service = CalendarApi::GoogleCalendarService.new(service_account)
        raw_events_by_calendar = service.fetch_events_in_range(three_years_ago, six_months_from_now)
        
        # Iterate through hashes
        raw_events_by_calendar.each do |calendar_id, raw_events|
          # Uses mapper to standardize JSON schema
          events.concat(CalendarApi::GoogleCalendarMapper.map_events(raw_events, calendar_id))
        end

      elsif service_account.provider == 'microsoft_graph'
        service = CalendarApi::OutlookCalendarService.new(service_account)
        raw_event_data = service.fetch_events_in_range(three_years_ago, six_months_from_now)
        # Uses mapper to standardize JSON schema
        events = CalendarApi::OutlookCalendarMapper.map_events(raw_event_data)
      end

      # Deduplicates event data
      dedup_events = events.uniq { |event| "#{event[:calendar_id]}-#{event[:event_id]}" }

      #Reformats data to make it easily readable
      readable_json = JSON.pretty_generate(dedup_events)

      export_directory = ENV['EXPORT_PATH']
      file_path = File.join(export_directory, "calendar_events_#{user.id}.json")
      File.open(file_path, 'w') do |file|
        file.write(readable_json)
      end

      # Update the status
      user.update(status: 'completed', last_sync_at: Time.now.utc)
    rescue Google::Apis::AuthorizationError, Faraday::ClientError => e
       # Check if the error is due to an expired refresh token
      if e.message.include?("Token has been revoked.") || e.message.include?("invalid_grant")
        # Notify the admin
        Rails.logger.error("Refresh token expired for user #{user.id}. Notifying admin.")
        # Send email notification to admin
        AdminMailer.refresh_token_expired(user).deliver_later
        user.update(status: 'failed')
      else
        # Handle other types of errors
        user.update(status: 'failed')
      end
    rescue => e
      # Failed to download
      if defined?(user) && user
        user.update(status: 'failed')
      end

      Rails.logger.error("FetchCalendarEventsJob failed for service_account_id #{service_account_id}: #{e.message}")
    end
  end
end