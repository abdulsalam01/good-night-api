Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  resources :users, only: [] do
    resources :clock_ins, only: [ :index, :create ], controller: "sleep_records"

    # Follow/Unfollow routes (using member routes with follower's user id in URL).
    member do
      post "follow/:followed_id" => "follows#create"
      delete "follow/:followed_id" => "follows#destroy"
      get "feed" => "sleep_records#friends_feed"
    end
  end
end
