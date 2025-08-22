class CalendarApi::GoogleCalendarMapper
  def self.map_events(events, calendar_id)
    events.map do |event|
      {
        event_id: event.id,
        calendar_id: calendar_id,
        start_at_utc: event.start&.date_time,
        end_at_utc: event.end&.date_time,
        status: event.status,
        last_modified_at_utc: event.updated,
        title: event.summary,
        location: event.location,
        event_notes: event.description,
        source: 'google'
      }
    end
  end
end