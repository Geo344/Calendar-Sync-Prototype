Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Handle OAuth callback and a place to display Calendar Events
  get '/auth/:provider/callback', to: 'sessions#create'
  get '/auth/failure', to: 'sessions#failure'

  # Logout
  delete '/logout', to: 'sessions#destroy'

  # Path for your 'connect account' or login page
  root 'sessions#home'

  # A simple profile/dashboard page to show success
  get '/profile', to: 'users#show', as: :profile

  # Allows for progress bar
  get 'user/calendar_status', to: 'users#calendar_status'
  
end
