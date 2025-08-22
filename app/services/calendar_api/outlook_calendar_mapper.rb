class CalendarApi::OutlookCalendarMapper
  def self.map_events(events)
    events.map do |event|
      {
        event_id: event['id'],
        calendar_id: event['calendarId'],
        start_at_utc: event['start']['dateTime'],
        end_at_utc: event['end']['dateTime'],
        status: event['isCancelled'] ? 'cancelled' : 'confirmed',
        title: event['subject'],
        location: event['location']['displayName'],
        event_notes: event['body']['content'], 
        last_modified_at_utc: event['lastModifiedDateTime'],
        source: 'microsoft'
      }
    end
  end
end