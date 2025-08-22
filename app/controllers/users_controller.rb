class UsersController < ApplicationController
  # Ensure the user is logged in before they can access their profile
  before_action :authenticate_user!

  # Action to display the user's profile
  def show
    # The `current_user` method is defined in ApplicationController
    # and makes the logged-in user object available here.
    # No need to fetch a user by ID from params, as we want to show
    # the currently authenticated user's profile.
    @user = current_user
  end

  def calendar_status
    if current_user && current_user.status
      render json: { status: current_user.status }
    else
      render json: { status: 'not_started' }
    end
  end

end