Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Root route
  root "assessments#index"

  # Assessment routes
  resources :assessments do
    member do
      get :preview
      post :add_section
      delete :remove_section
      post :add_question
      delete :remove_question
      patch :update_question
      post :add_option
      delete :remove_option
      patch :update_option
    end

    # Nested section routes for more complex operations
    resources :assessment_sections, only: [:create, :update, :destroy], path: 'sections' do
      resources :assessment_questions, only: [:create, :update, :destroy], path: 'questions'
    end
  end

  # API routes for AJAX functionality
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :assessments, only: [:show, :update] do
        resources :sections, only: [:create, :update, :destroy]
        resources :questions, only: [:create, :update, :destroy]
      end
    end
  end
end
