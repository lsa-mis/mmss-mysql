Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  devise_for :faculties, controllers: {
    sessions: 'faculties/sessions'
  }

  get 'faculty', to: 'faculties#index'
  get 'faculty/student_list/:id', to: 'faculties#student_list', as: :student_list
  get 'faculty/student_page/:id', to: 'faculties#student_page', as: :student_page
  get 'faculty_login', to: 'static_pages#faculty_login', as: :faculty_login

  resources :rejections
  resources :campnotes
  resources :recuploads
  resources :feedbacks
  # resources :payments
  root to: 'static_pages#index'

  devise_for :admins, ActiveAdmin::Devise.config
  get '/admin/reports/all_complete_apps', to: 'admin/reports#all_complete_apps', as: :admin_reports_all_complete_apps
  get '/admin/reports/registered_but_not_applied', to: 'admin/reports#registered_but_not_applied', as: :admin_reports_registered_but_not_applied
  get '/admin/reports/enrolled_with_addresses', to: 'admin/reports#enrolled_with_addresses', as: :admin_reports_enrolled_with_addresses
  get '/admin/reports/pending_course_assignments_with_students', to: 'admin/reports#pending_course_assignments_with_students', as: :admin_reports_pending_course_assignments_with_students
  get '/admin/reports/accepted_course_assignments_with_students', to: 'admin/reports#accepted_course_assignments_with_students', as: :admin_reports_accepted_course_assignments_with_students
  get '/admin/reports/enrolled_student_demographic_report', to: 'admin/reports#enrolled_student_demographic_report', as: :admin_reports_enrolled_student_demographic_report
  get '/admin/reports/complete_apps_demographic_report', to: 'admin/reports#complete_apps_demographic_report', as: :admin_reports_complete_apps_demographic_report
  get '/admin/reports/enrolled_events_per_session', to: 'admin/reports#events_per_session_for_enrolled', as: :admin_reports_enrolled_events_per_session
  get '/admin/reports/complete_applications_with_course_preferences', to: 'admin/reports#complete_applications_with_course_preferences', as: :admin_reports_complete_applications_with_course_preferences
  get '/admin/reports/waitlisted_applications_with_course_preferences', to: 'admin/reports#waitlisted_applications_with_course_preferences', as: :admin_reports_waitlisted_applications_with_course_preferences
  get '/admin/reports/enrolled_with_sessions_and_courses', to: 'admin/reports#enrolled_with_sessions_and_courses', as: :admin_reports_enrolled_with_sessions_and_courses
  get '/admin/reports/enrolled_with_sessions_and_tshirt', to: 'admin/reports#enrolled_with_sessions_and_tshirt', as: :admin_reports_enrolled_with_sessions_and_tshirt
  get '/admin/reports/course_assignments', to: 'admin/reports#course_assignments', as: :admin_reports_course_assignments
  get '/admin/reports/enrolled_with_covid_verification', to: 'admin/reports#enrolled_with_covid_verification', as: :admin_reports_enrolled_with_covid_verification
  get '/admin/reports/enrolled_with_addresses_and_more', to: 'admin/reports#enrolled_with_addresses_and_more', as: :admin_reports_enrolled_with_addresses_and_more
  get '/admin/reports/enrolled_for_more_than_one_session', to: 'admin/reports#enrolled_for_more_than_one_session', as: :admin_reports_enrolled_for_more_than_one_session
  get '/admin/reports/dorm_by_gender_by_session', to: 'admin/reports#dorm_by_gender_by_session', as: :admin_reports_dorm_by_gender_by_session
  get '/admin/reports/finaid_with_app_and_offer_status', to: 'admin/reports#finaid_with_app_and_offer_status', as: :admin_reports_finaid_with_app_and_offer_status
  get '/admin/reports/offer_accepted_with_balance_due', to: 'admin/reports#offer_accepted_with_balance_due', as: :admin_reports_offer_accepted_with_balance_due

  ActiveAdmin.routes(self)
  # authenticated :admin do
    resources :genders
    resources :demographics

    resources :camp_configurations do
      resources :camp_occurrences
    end

    resources :camp_occurrences do
      resources :activities
    end

    resources :camp_occurrences do
      resources :courses
    end

    resources :activities
    resources :courses
  # end

  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }
  resources :applicant_details

  resources :enrollments do
    resources :travels
  end

  resources :enrollments do
    resources :activities
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
    resources :course_preferences
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

  post 'waitlisted/:id', to: 'enrollments#add_to_waitlist', as: :waitlisted
  post 'remove_from_waitlist/:id', to: 'enrollments#remove_from_waitlist', as: :remove_from_waitlist
  post 'withdraw/:id', to: 'enrollments#withdraw', as: :withdraw_enrollment

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

  get 'send_request_email', to: 'recommendations#send_request_email', as: :send_request_email

  get 'send_finaid_request_email', to: 'enrollments#send_finaid_request_email', as: :send_finaid_request_email

end
