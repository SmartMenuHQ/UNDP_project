Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication routes
      scope :auth do
        post :login, to: "auth#login"
        delete :logout, to: "auth#logout"
        post :refresh, to: "auth#refresh"
        get :me, to: "auth#me"
        delete :logout_all, to: "auth#logout_all"
      end

      # Business user routes (read-only access)
      resources :assessments, only: [ :index, :show ] do
        member do
          get :sections
          get :questions
          get :visibility_summary
        end
      end

      resources :users, only: [ :show, :update ]
      resources :countries, only: [ :index, :show ]

      # Business (non-admin) namespace for response sessions and responses
      namespace :business do
        resources :assessments, only: [] do
          resources :response_sessions, path: "response-sessions", only: [ :index, :show, :create, :update ] do
            member do
              patch :start
              get "sections/:section_id", to: "response_sessions#show_section", as: :show_section
              get "section_responses/:section_id", to: "response_sessions#section_responses", as: :section_responses
              patch "sections/:section_id/submit", to: "response_sessions#submit_section", as: :submit_section
            end
          end
        end
      end

      # Response sessions for taking assessments
      resources :response_sessions, path: "response-sessions" do
        member do
          patch :start
          patch :submit
        end
      end

      # Admin routes
      namespace :admin do
        resources :users do
          member do
            patch :make_admin
            patch :remove_admin
          end
          collection do
            post :invite
          end
        end

        resources :countries do
          member do
            patch :activate
            patch :deactivate
            get :statistics
          end
        end

        resources :assessments do
          resources :sections, controller: "assessment_sections", path: "sections" do
            resources :questions, controller: "assessment_questions", path: "questions"
          end

          # Marking schemes and rules (Admin API)
          resources :marking_schemes, controller: "marking_schemes", path: "marking-schemes" do
            member do
              post :activate
              post :clone
            end

            resources :rules, controller: "marking_rules", path: "rules" do
              collection do
                post :bulk_create
                get :rule_types
                get :criteria_fields
              end
            end
          end
        end

        # Question options management
        resources :questions, only: [] do
          resources :options, controller: "question_options", path: "options" do
            collection do
              post :reorder
            end
          end
        end
      end
    end
  end
  resource :session
  resources :passwords, param: :token
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
    resources :assessment_sections, only: [ :create, :update, :destroy ], path: "sections" do
      resources :assessment_questions, only: [ :create, :update, :destroy ], path: "questions"
    end

    # Question options API endpoint
    get "questions/:question_id/options", to: "assessments#question_options"

    # Nested routes for marking schemes and rules
    resources :marking_schemes, path: "marking-schemes", controller: "marking_schemes" do
      member do
        patch :activate
        patch :deactivate
        post :duplicate
      end

      # Nested routes for marking rules
      resources :marking_rules, path: "rules", controller: "marking_rules" do
        collection do
          post :bulk_create
          get :rule_types
          get :criteria_fields
        end

        member do
          patch :move_up
          patch :move_down
        end
      end
    end

    # Nested routes for response sessions
    resources :response_sessions, path: "responses", controller: "response_sessions" do
      collection do
        post :bulk_mark
        post :bulk_publish
        get :analytics
        get :export
      end

      member do
        get :start
        get :submit
        get :mark
        get :publish
        get :cancel
        get :reset
        patch :start
        patch :submit
        patch :mark
        patch :publish
        patch :cancel
        patch :reset
      end
    end
  end

  # API routes for AJAX functionality
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :assessments, only: [ :show, :update ] do
        resources :sections, only: [ :create, :update, :destroy ]
        resources :questions, only: [ :create, :update, :destroy ]
      end
    end
  end

  # Admin routes for monitoring
  namespace :admin do
    get :job_status
    get :jobs
  end

  # SPA routes - catch-all for client-side routing
  # This should be last to avoid interfering with other routes
  get "/app", to: "app#index"
  get "/app/*path", to: "app#index"
end
