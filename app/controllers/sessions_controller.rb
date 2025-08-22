class SessionsController < ApplicationController
  def create
    auth = request.env['omniauth.auth'] # OmniAuth provides the auth hash here

    begin
    user, service_account = find_or_create_user_and_account(auth)

    session[:user_id] = user.id

    # Enqueue the background job to fetch calendar data
    FetchCalendarEventsJob.perform_later(service_account.id)

    # Redirect the user to a page that indicates the download is in progress
    redirect_to profile_path, notice: "You've successfully connected your account. Your calendar data is being prepared for download."

    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "User creation/update failed after OAuth: #{e.record.errors.full_messages.to_sentence}"
      flash[:alert] = "Could not process your login: #{e.record.errors.full_messages.to_sentence}"
      redirect_to root_path # Redirect back to homepage on validation error
    rescue => e
      Rails.logger.error "Unexpected error during OAuth callback: #{e.message}\n#{e.backtrace.join("\n")}"
      flash[:alert] = "An unexpected error occurred during authentication. Please try again."
      redirect_to root_path # Redirect back to homepage on any other error
    end
  end

  private

  def find_or_create_user_and_account(auth)
    # Find or create the user based on the email from the auth hash
    user = User.find_or_create_by!(email: auth.info.email) do |u|
      u.name = auth.info.name
    end

    # Find or create the service account linked to the user
    service_account = ServiceAccount.find_or_create_by!(user: user, provider: auth.provider) do |sa|
      sa.provider_uid = auth.uid
      sa.access_token = auth.credentials.token
      sa.refresh_token = auth.credentials.refresh_token
      sa.expires_at = Time.at(auth.credentials.expires_at)
      sa.scopes = auth.credentials.scopes&.join(',') # Join the array of scopes into a string
      sa.name = auth.info.name
      sa.email = auth.info.email
    end

    # If the service account already exists, update its credentials
    unless service_account.new_record?
      service_account.update!(
        access_token: auth.credentials.token,
        refresh_token: auth.credentials.refresh_token,
        expires_at: Time.at(auth.credentials.expires_at),
        scopes: auth.credentials.scopes&.join(','),
        name: auth.info.name,
        email: auth.info.email
      )
    end

    [user, service_account]
  end

  public 

  # Handles failed authentication attempts
  def failure
    message = params[:message] || "Unknown connection error"

    humanized_message = message.to_s.humanize

    Rails.logger.warn "OAuth connection failure: #{humanized_message}"
    flash[:alert] = "Failed to connect account: #{humanized_message}. Please try again."
    redirect_to root_path # Redirect back to the home page or a prompt
  end

  # Logs out the user by clearing their application session.
  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: 'You have been disconnected.'
  end

  def home
    # Renders homepage
  end
end