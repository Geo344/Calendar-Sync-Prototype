class ServiceAccount < ApplicationRecord
  belongs_to :user
  # Validations for service_account table
  validates :provider, presence: true
  validates :provider_uid, presence: true, uniqueness: { scope: :provider }
  validates :access_token, presence: true
end
