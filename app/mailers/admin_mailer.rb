class AdminMailer < ApplicationMailer

  default to: "fl51@rice.edu" # Set the admin's email address here
  
  def refresh_token_expired(user)
    @user = user
    mail(subject: "Alert: Refresh Token Expired for #{@user.email}")
  end

  
end
