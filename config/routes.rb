Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development? || Rails.env.staging?

  devise_for :faculties, controllers: {
    sessions: 'faculties/sessions'
  }

  get 'faculty', to: 'faculties#index'
  get 'faculty/student_list/:id', to: 'faculties#student_list', as: :student_list
  get 'faculty/student_page/:id', to: 'faculties#student_page', as: :student_page
  get 'faculty_login', to: 'static_pages#faculty_login', as: :faculty_login

  resources :rejections
  resources :recuploads
  resources :feedbacks
  # resources :payments
  root to: 'static_pages#index'

  # Admin authentication (Devise `Admin` model) is served by the new admin at /admin/login etc.
  # Route helper names (new_admin_session_path, destroy_admin_session_path) are unchanged.
  devise_for :admins, path: 'admin',
                      path_names: { sign_in: 'login', sign_out: 'logout' },
                      controllers: { sessions: 'admins/sessions', passwords: 'admins/passwords', unlocks: 'admins/unlocks' }

  # New plain-MVC admin. Resources are ported here from app/admin one menu group at a time.
  namespace :admin do
    root to: 'dashboard#index'

    # Admins never create enrollments (applicants do, through the public flow), so no new/create.
    resources :applications, except: %i[new create] do
      collection { post :batch }
      # Status mutations formerly exposed on the public EnrollmentsController; admin-only now.
      member do
        post :waitlist
        post :remove_from_waitlist
        post :withdraw
        post :send_finaid_request_email
      end
    end

    # Recommendations are ported in a later PR; only the admin-only "resend request" action lives here
    # (it used to be a public GET on RecommendationsController).
    resources :recommendations, only: [] do
      member { post :send_request_email }
    end

    resources :comments, only: %i[index create destroy]

    # Camp Setup
    resources :camp_configurations do
      collection { post :batch }
    end
    resources :session_configurations do
      collection { post :batch }
    end
    resources :activities do
      collection { post :batch }
    end
    resources :courses do
      collection { post :batch }
    end
    resources :campnotes do
      collection { post :batch }
    end
    resources :demographics do
      collection { post :batch }
    end
    resources :gender_types do
      collection { post :batch }
    end

    # Cutover aid: bookmarks and links to resources that are not ported yet keep working.
    # Remove together with ActiveAdmin.
    get '*path', format: false, to: redirect { |path_params, request|
      "/legacy_admin/#{path_params[:path]}#{"?#{request.query_string}" if request.query_string.present?}"
    }
  end

  # Legacy ActiveAdmin admin, mounted at /legacy_admin until every resource is ported (see
  # config/initializers/active_admin.rb). Report routes are explicit ActiveAdmin page actions.
  %w[
    all_complete_apps registered_but_not_applied enrolled_with_addresses
    pending_course_assignments_with_students accepted_course_assignments_with_students
    enrolled_student_demographic_report complete_apps_demographic_report
    complete_applications_with_course_preferences waitlisted_applications_with_course_preferences
    enrolled_with_sessions_and_courses enrolled_with_sessions_and_tshirt course_assignments
    enrolled_with_covid_verification enrolled_with_addresses_and_more enrolled_for_more_than_one_session
    dorm_by_gender_by_session finaid_with_app_and_offer_status offer_accepted_with_balance_due
  ].each do |report|
    get "/legacy_admin/reports/#{report}", to: "legacy_admin/reports##{report}", as: :"legacy_admin_reports_#{report}"
  end
  get '/legacy_admin/reports/enrolled_events_per_session', to: 'legacy_admin/reports#events_per_session_for_enrolled',
                                                           as: :legacy_admin_reports_enrolled_events_per_session

  ActiveAdmin.routes(self)

  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }
  resources :applicant_details

  resources :enrollments do
    resources :travels
  end

  resources :enrollments do
      resources :financial_aids
  end

  resources :financial_aids

  resources :enrollments do
    resources :recommendations
  end

  resources :recommendations

  resources :enrollments do
      resources :course_preferences do
        collection do
          patch :bulk_update
        end
      end
  end

  resources :enrollments do
    resources :course_assignments
  end

  resources :enrollments do
    resources :session_assignments
  end

  resources :course_preferences
  resources :course_assignments
  resources :session_assignments

  # post 'accept_offer', to: 'enrollments#accept_offer'
  # post 'decline_offer', to: 'enrollments#decline_offer'

  post 'accept_session_offer/:id', to: 'session_assignments#accept_session_offer', as: :accept_session_offer
  post 'decline_session_offer/:id', to: 'session_assignments#decline_session_offer', as: :decline_session_offer


  get 'static_pages/index'
  get 'static_pages/contact'
  get 'static_pages/privacy'

  get 'payments', to: 'payments#index'
  get 'payment_receipt', to: 'payments#payment_receipt'
  post 'payment_receipt', to: 'payments#payment_receipt'
  get 'payment_show', to: 'payments#payment_show', as: 'all_payments'
  get 'make_payment', to: 'payments#make_payment'
  post 'make_payment', to: 'payments#make_payment'

  get 'recupload_error', to: 'recuploads#error'
  get 'recupload_success', to: 'recuploads#success'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html



end
