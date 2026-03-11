Rails.application.routes.draw do
  devise_for :users,
             skip: %i[sessions registrations],
             defaults: { format: :json },
             controllers: {
               sessions: "api/v1/auth/sessions",
               registrations: "api/v1/auth/registrations"
             }

  devise_scope :user do
    post "api/v1/auth/signup", to: "api/v1/auth/registrations#create"
    patch "api/v1/auth/account", to: "api/v1/auth/registrations#update"
    put "api/v1/auth/account", to: "api/v1/auth/registrations#update"
    post "api/v1/auth/login", to: "api/v1/auth/sessions#create"
    delete "api/v1/auth/logout", to: "api/v1/auth/sessions#destroy"
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :tasks, only: %i[index show create update]
      resources :task_occurrences, only: %i[create update destroy]
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
