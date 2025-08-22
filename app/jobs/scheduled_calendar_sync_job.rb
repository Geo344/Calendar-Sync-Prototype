class ScheduledCalendarSyncJob < ApplicationJob
  queue_as :default

  def perform
    #checks for users that haven't been synced in the past week.
    users_to_sync = User.where("last_sync_at < ? OR last_sync_at IS NULL", 1.week.ago)

    users_to_sync.each do |user|
      user.service_accounts.each do |service_account|
        # Use a new job to handle the heavy lifting
        FetchCalendarEventsJob.perform_later(service_account.id)
      end
    end
  end
end
