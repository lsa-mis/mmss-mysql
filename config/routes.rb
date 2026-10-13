Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development? || Rails.env.staging?

  devise_for :faculties, controllers: {
    sessions: "faculties/sessions"
  }

  get "faculty", to: "faculties#index"
  get "faculty/student_list/:id", to: "faculties#student_list", as: :student_list
  get "faculty/student_page/:id", to: "faculties#student_page", as: :student_page
  get "faculty_login", to: "static_pages#faculty_login", as: :faculty_login

  # Recommenders upload letters through the emailed link; everything else is under /admin/recuploads.
  resources :recuploads, only: %i[new create]
  resources :feedbacks
  # resources :payments
  root to: "static_pages#index"

  # Admin authentication (Devise `Admin` model) is served by the new admin at /admin/login etc.
  # Route helper names (new_admin_session_path, destroy_admin_session_path) are unchanged.
  devise_for :admins, path: "admin",
    path_names: {sign_in: "login", sign_out: "logout"},
    controllers: {sessions: "admins/sessions", passwords: "admins/passwords", unlocks: "admins/unlocks"}

  # New plain-MVC admin. Resources are ported here from app/admin one menu group at a time.
  namespace :admin do
    root to: "dashboard#index"

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

    # Money: financial_aid_requests = FinancialAid (the legacy admin's resource name). Applicant details
    # and payments have no destroy (payments are financial records).
    resources :applicant_details, except: :destroy
    resources :financial_aid_requests, controller: "financial_aid_requests" do
      collection { post :batch }
    end
    resources :payments, except: :destroy

    # Applicant Info (models named after their legacy admin resource where they differ; the
    # controllers keep the model): session_selections = SessionActivity,
    # applicant_activities = EnrollmentActivity.
    resources :course_assignments do
      collection { post :batch }
    end
    resources :course_preferences do
      collection { post :batch }
    end
    resources :session_selections, controller: "session_selections" do
      collection { post :batch }
    end
    resources :session_assignments do
      collection { post :batch }
    end
    resources :applicant_activities, controller: "applicant_activities" do
      collection { post :batch }
    end
    resources :recommendations do
      collection { post :batch }
      # "Resend request" used to be a public GET on RecommendationsController; admin-only now.
      member { post :send_request_email }
    end
    resources :recuploads do
      collection { post :batch }
    end
    resources :rejections do
      collection { post :batch }
    end
    resources :travels do
      collection { post :batch }
    end
    # Read-only audit trails of the Nelnet payment flow.
    resources :payment_requests, only: %i[index show]
    resources :nelnet_callback_logs, only: %i[index show]

    resources :comments, only: %i[index create destroy]

    # CSV reports: /admin/reports lists them, /admin/reports/<key> downloads one. Any id reaches the
    # controller (no constraint, no format suffix) so unknown/malformed keys get the controller's
    # redirect instead of falling through to the legacy catch-all below.
    resources :reports, only: %i[index show], format: false, constraints: {id: %r{[^/]+}}

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

    # Logins Info
    resources :admins do
      collection { post :batch }
      member { post :unlock }
    end
    resources :users do
      collection { post :batch }
    end
    resources :faculties, only: %i[index show destroy] do
      collection { post :batch }
    end
    # Feedback is submitted by applicants on the public site; admins only review/edit/delete it.
    resources :feedbacks, except: %i[new create] do
      collection { post :batch }
    end
  end

  # The legacy admin ran at /legacy_admin during the cutover. Old bookmarks land on the new
  # admin's dashboard (the legacy URL structure does not map 1:1 onto the new routes).
  get "/legacy_admin(/*path)", to: redirect("/admin", status: 301), format: false

  devise_for :users, controllers: {
    registrations: "users/registrations"
  }
  # Applicant-facing; the admin listing lives under /admin/applicant_details (no destroy anywhere).
  resources :applicant_details, except: %i[index destroy]

  # Applicant-facing application (one per camp year); the admin listing, status changes and
  # deletion live under /admin/applications. The nested resources are applicant-facing too; their
  # admin listings/deletions live under /admin/travels, /admin/financial_aid_requests,
  # /admin/recommendations, /admin/course_preferences and /admin/session_assignments.
  resources :enrollments, except: %i[index destroy] do
    resources :travels, except: %i[index destroy]
    resources :financial_aids, except: %i[index destroy]
    resources :recommendations, except: %i[index destroy]
    resources :course_preferences do
      collection do
        patch :bulk_update
      end
    end
    resources :session_assignments
  end

  resources :financial_aids, except: %i[index destroy]
  resources :recommendations, except: %i[index destroy]
  resources :course_preferences
  resources :session_assignments

  post "accept_session_offer/:id", to: "session_assignments#accept_session_offer", as: :accept_session_offer
  post "decline_session_offer/:id", to: "session_assignments#decline_session_offer", as: :decline_session_offer

  get "static_pages/index"
  get "static_pages/contact"
  get "static_pages/privacy"

  get "payment_receipt", to: "payments#payment_receipt"
  post "payment_receipt", to: "payments#payment_receipt"
  get "payment_show", to: "payments#payment_show", as: "all_payments"
  get "make_payment", to: "payments#make_payment"
  post "make_payment", to: "payments#make_payment"

  get "recupload_error", to: "recuploads#error"
  get "recupload_success", to: "recuploads#success"
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
