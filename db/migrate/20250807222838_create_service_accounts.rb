class CreateServiceAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :service_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :provider_uid, null: false
      t.string :access_token, null: false
      t.string :refresh_token
      t.datetime :expires_at
      t.string :scopes
      t.string :name
      t.string :email
      
      t.timestamps
    end
  end
end
