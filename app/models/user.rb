class User < ApplicationRecord
  has_many :service_accounts, dependent: :destroy

  # Basic validations
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  # Method to find or create a user, and their service account
  def self.from_omniauth(auth)

    # Find or create the main User record 
    user = User.find_or_create_by(email: auth.info.email) do |u|
      u.name = auth.info.name
    end

    # Find or create the specific ServiceAccount for this provider
    service_account = user.service_accounts.find_or_initialize_by(
      provider: auth.provider,
      provider_uid: auth.uid
    ) do |sa|
      sa.name = auth.info.name
      sa.email = auth.info.email
    end

    # Always update service account tokens and info
    service_account.access_token = auth.credentials.token
    service_account.refresh_token = auth.credentials.refresh_token
    service_account.expires_at = Time.at(auth.credentials.expires_at) if auth.credentials.expires_at.present?
    service_account.scopes = auth.credentials.scope # Save space-separated scopes

    service_account.save! # Save the service account changes
    user # Return the main user object
  end

  # Helper to get a specific service account
  def service_account_for(provider_name)
    service_accounts.find_by(provider: provider_name.to_s)
  end

end
