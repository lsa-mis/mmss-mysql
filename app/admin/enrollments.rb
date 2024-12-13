ActiveAdmin.register Enrollment, as: 'Application' do
  menu parent: 'Applicant Info', priority: 1

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params  :user_id, :international,
                 :high_school_name, :high_school_address1,
                 :high_school_address2, :high_school_city,
                 :high_school_state, :high_school_non_us,
                 :high_school_postalcode, :high_school_country,
                 :year_in_school, :anticipated_graduation_year,
                 :room_mate_request, :personal_statement, :camp_doc_form_completed,
                 :shirt_size, :notes, :application_status, :application_status_updated_on, :campyear,
                 :offer_status, :partner_program, :transcript, :student_packet,
                 :application_deadline, :vaccine_record, :covid_test_record, :uniqname,
                 session_assignments_attributes: %i[id camp_occurrence_id _destroy],
                 course_assignments_attributes: %i[id course_id wait_list _destroy]

  scope :current_camp_year_applications, default: true, label: 'Current years Applications'
  scope :all

  scope :offered, group: :offer_status
  scope :accepted, group: :offer_status

  scope :application_complete, group: :application_status
  scope :application_complete_not_offered, group: :application_status
  scope :enrolled, group: :application_status

  scope :no_recomendation, group: :missing
  scope :no_letter, group: :missing
  scope :no_payments, group: :missing
  scope :no_camp_doc_form, group: :missing

  action_item :set_waitlisted, only: :show do
    if ['application complete'].include? application.application_status
      text_node link_to('Place on Wait List', waitlisted_path(application),
                        data: { confirm: 'Are you sure you want to wait list this application?' }, method: :post)
    end
  end
  action_item :remove_from_waitlist, only: :show do
    if ['waitlisted'].include? application.application_status
      text_node link_to('Remove from Wait List', remove_from_waitlist_path(application),
                        data: { confirm: 'Are you sure you want to remove this application from wait list?' }, method: :post)
    end
  end
  action_item :set_rejected, only: :show do
    if ['application complete'].include? application.application_status
      text_node link_to('Reject Applicant',
                        new_admin_rejection_path(enrollment_id: application))
    end
  end

  form do |f| # This is a formtastic form builder
    f.semantic_errors(*f.object.errors.keys) # shows errors on :base
    f.inputs do
      f.input :user_id, as: :select, collection: User.all.order(:email)
      f.input :uniqname if application.application_status == 'enrolled'
      f.input :international
      f.input :campyear
      f.input :high_school_name
      f.input :high_school_address1
      f.input :high_school_address2
      f.input :high_school_city
      f.input :high_school_state, as: :select, collection: us_states
      f.input :high_school_non_us
      f.input :high_school_postalcode
      f.input :high_school_country
      f.input :year_in_school, as: :select, collection: year_in_school
      f.input :anticipated_graduation_year
      f.input :room_mate_request
      f.input :personal_statement

      table_for application do
        column 'Current Transcript' do |item|
          link_to item.transcript.filename, url_for(item.transcript) if item.transcript.attached?
        end
      end
      f.input :transcript, as: :file, label: 'Update transcript'
      f.input :camp_doc_form_completed
      hr
      f.input :notes
      f.input :partner_program
    end

    f.inputs do
      f.semantic_errors
      f.has_many :session_assignments, heading: 'Session Assignments',
                                       allow_destroy: true,
                                       new_record: true do |a|
        a.input :offer_status, input_html: { disabled: true }
        a.input :camp_occurrence_id, as: :select, collection: application.session_registrations
      end
      text_node '&nbsp;&nbsp;&nbsp;&nbsp; * if you delete a session assignment be certain to delete any corresponding course assignment'.html_safe
    end

    f.inputs do
      f.semantic_errors
      f.has_many :course_assignments, heading: 'Course Assignments',
                                      allow_destroy: true,
                                      new_record: true do |a|
        a.input :course_id, as: :select, collection:
          application.course_registrations.order(:camp_occurrence_id).map { |u|
            ["#{u.title}, #{u.camp_occurrence.description},
                      rank - #{application.course_preferences.find_by(course_id: u.id).ranking}, available - #{u.available_spaces - CourseAssignment.number_of_assignments(u.id)}", u.id]
          }
        a.input :wait_list
      end
    end
    if application.session_assignments.any? and application.course_assignments.any?
      f.inputs do
        f.input :offer_status, as: :select, collection: %w[accepted declined offered]
        f.input :application_deadline
        f.input :application_status, as: :select,
                                     collection: ['enrolled', 'application complete', 'offer accepted', 'offer declined', 'submitted']
      end
    end
    f.actions # adds the 'Submit' and 'Cancel' button
  end

  filter :applicant_detail_lastname_start, label: 'Last Name (Starts with)'
  filter :applicant_detail_firstname_start, label: 'First Name (Starts with)'
  filter :international
  filter :year_in_school, as: :select, collection: proc {
    Enrollment.current_camp_year_applications.pluck(:year_in_school)
  }
  filter :anticipated_graduation_year, as: :select
  filter :application_status, as: :select
  filter :offer_status, as: :select
  filter :application_deadline
  filter :campyear, as: :select

  index do
    selectable_column
    actions
    column :updated_at
    column 'Applicant' do |application|
      link_to application.display_name, admin_user_path(application.user_id)
    end
    column 'Transcript' do |enroll|
      link_to enroll.transcript.filename, url_for(enroll.transcript) if enroll.transcript.attached?
    end
    column :camp_doc_form_completed
    column :offer_status
    column :application_deadline
    column :application_status
    column :application_status_updated_on
    column :international
    column :year_in_school
    column :anticipated_graduation_year
    column :room_mate_request
    column :notes
    column :partner_program
    column 'Balance Due' do |application|
      humanized_money_with_symbol(PaymentState.new(application).balance_due / 100)
    end
    column 'Camp Year' do |app|
      app.campyear
    end
  end

  show do
    attributes_table do
      row :user_id do |user|
        link_to(user.applicant_detail.full_name.titleize, admin_applicant_detail_path(user.applicant_detail))
      end
      row :uniqname if application.application_status == 'enrolled'
      row :personal_statement
      row :notes
      row :offer_status
      row :application_deadline
      row :application_status
      row :application_status_updated_on
      row :partner_program
      row :application_fee_required
      row :campyear
    end

    panel 'Session Assignment' do
      table_for application.session_assignments do
        column(:id) { |item| link_to(item.id, admin_session_assignment_path(item)) }
        column('Session') { |item| item.camp_occurrence.description }
        column(:offer_status)
      end

      table_for application.session_registrations do
        column 'User Selected Sessions' do |item|
          item.description
        end
      end
    end

    panel 'Course Assignment' do
      table_for application.course_assignments do
        column(:id) { |item| link_to(item.id, admin_course_assignment_path(item)) }
        column(:course_id) { |item| item.course.title }
        column 'Session' do |item|
          item.course.camp_occurrence.description
        end
        column :wait_list
      end

      table_for application.course_preferences do
        column 'User Course Preference' do |item|
          item.course.title
        end
        column 'Rank' do |item|
          item.ranking
        end
        column 'Session' do |item|
          item.course.camp_occurrence.description
        end
        column 'Available' do |item|
          item.course.available_spaces - CourseAssignment.number_of_assignments(item.course_id)
        end
      end
    end

    panel 'Activities/Services' do
      table_for Activity.where(camp_occurrence_id: application.session_assignments.accepted.pluck(:camp_occurrence_id)).order(:camp_occurrence_id).where(id: application.enrollment_activities.pluck(:activity_id)) do
        column 'Assigned Activities' do |item|
          item.description
        end
        column 'Session' do |item|
          item.camp_occurrence.description
        end
      end

      table_for application.enrollment_activities do
        column 'User Selected Activites' do |item|
          item.activity.description
        end
        column 'Session' do |item|
          item.activity.camp_occurrence.description
        end
      end
    end

    app_pay_status = PaymentState.new(application)
    panel "Finances -- [Balance Due: #{humanized_money_with_symbol(app_pay_status.balance_due / 100)} Total Cost: #{humanized_money_with_symbol(app_pay_status.total_cost / 100)}]  " do
      panel 'Payment Activity' do
        unless application.application_fee_required
          text_node '<strong>!! This application was submitted after the Application Fee Requirement was turned off !!</strong>'.html_safe
        end
        table_for application.user.payments.current_camp_payments do
          column(:id) { |aid| link_to(aid.id, admin_payment_path(aid.id)) }
          column(:account_type) { |atype| atype.account_type.titleize }
          column(:transaction_date) { |td| Date.parse(td.transaction_date) }
          column(:transaction_status) { |ts| transaction_status_message(ts.transaction_status) }
          column(:total_amount) { |ta| humanized_money_with_symbol(ta.total_amount.to_f / 100) }
        end
      end

      text_node link_to('[Send Financial Aid Request Link to Applicant]',
                        send_finaid_request_email_path(enrollment_id: application))
      text_node ' --- '
      text_node link_to('[Add Financial Aid Request]',
                        new_admin_financial_aid_request_path(enrollment_id: application))
      text_node ' --- '
      text_node link_to('[Add Manual Payment]', new_admin_payment_path(enrollment_id: application))

      if application.financial_aids.present?
        panel 'Financial Aid Request' do
          table_for FinancialAid.where(enrollment_id: application) do
            column 'Request' do |item|
              link_to('view', admin_financial_aid_request_path(item)) if item.present?
            end
            column 'Amount' do |item|
              humanized_money_with_symbol(item.amount) if item.present?
            end
            column 'Status' do |item|
              item.status if item.present?
            end
          end
        end
      end
    end

    panel 'Recommendation' do
      if application.recommendation.present?
        table_for application.recommendation do
          column(:id) { |recc| link_to(recc.id, admin_recommendation_path(recc.id)) }
          column :firstname
          column :lastname
          column :organization
          column 'Letter' do |item|
            if item.recupload.present?
              link_to('view', admin_recupload_path(item.recupload))
            else
              '- waiting for response'
            end
          end
        end
      end
    end

    active_admin_comments
  end

  sidebar 'Details', only: :show do
    attributes_table_for application do
      row :id
      row :transcript do |tr|
        link_to tr.transcript.filename, url_for(tr.transcript) if tr.transcript.attached?
      end
      row :camp_doc_form_completed
      row :international
      row :high_school_name
      row :high_school_address1
      row :high_school_address2
      row :high_school_city
      row :high_school_state
      row :high_school_non_us
      row :high_school_postalcode
      row :high_school_country
      row :year_in_school
      row :anticipated_graduation_year
      row :room_mate_request
    end
  end

  csv do
    column :updated_at
    column 'Name' do |app|
      app.applicant_detail.full_name
    end
    column 'email' do |app|
      app.user.email
    end
    column 'Transcript' do |enroll|
      'uploaded' if enroll.transcript.attached?
    end
    column :offer_status
    column :application_deadline
    column :application_status
    column :application_status_updated_on
    column :international
    column :year_in_school
    column :anticipated_graduation_year
    column :room_mate_request
    column :notes
    column :partner_program
    column :camp_doc_form_completed
    column 'Balance Due' do |app|
      humanized_money_with_symbol(PaymentState.new(app).balance_due / 100)
    end
    column 'Camp Year' do |app|
      app.campyear
    end
  end
end
