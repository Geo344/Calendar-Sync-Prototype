class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_user, :logged_in?

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    !!current_user
  end

  def authenticate_user!
    unless logged_in? # Check if the user is logged in using your helper
      flash[:alert] = "You must be logged in to access that page."
      redirect_to root_path # Redirect to your homepage or a dedicated login path
      # Important: `return` halts the execution of the controller action
      # after the redirect, preventing "double render" errors or
      # unnecessary processing.
      return
    end
  end

end
