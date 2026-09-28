# frozen_string_literal: true

# Applications = Enrollment records (the ActiveAdmin resource was registered `as: 'Application'`).
# Reference implementation for porting resources: filters, scopes, sorting, pagination, CSV,
# batch actions, comments, admin-only member actions and a custom update flow (withdrawal).
#
# There is deliberately no new/create: applicants create their own enrollment through the public
# flow (session/course registrations, transcript), and the ActiveAdmin form never satisfied the
# model validations either.
class Admin::ApplicationsController < Admin::BaseController
  before_action :set_application, except: %i[index batch]

  SCOPES = [
    Admin::Scope.new(:current_camp_year_applications, label: 'Current years Applications', default: true),
    Admin::Scope.new(:all, label: 'All'),
    Admin::Scope.new(:offered, group: :offer_status),
    Admin::Scope.new(:accepted, group: :offer_status),
    Admin::Scope.new(:application_complete, group: :application_status),
    Admin::Scope.new(:application_complete_not_offered, group: :application_status),
    Admin::Scope.new(:enrolled, group: :application_status),
    Admin::Scope.new(:withdrawn, group: :application_status),
    Admin::Scope.new(:no_recomendation, label: 'No recommendation', group: :missing),
    Admin::Scope.new(:no_letter, group: :missing),
    Admin::Scope.new(:no_payments, group: :missing),
    Admin::Scope.new(:no_camp_doc_form, group: :missing)
  ].freeze

  SORTS = {
    updated_at: 'enrollments.updated_at',
    applicant: 'applicant_details.lastname',
    camp_doc_form_completed: 'enrollments.camp_doc_form_completed',
    offer_status: 'enrollments.offer_status',
    application_deadline: 'enrollments.application_deadline',
    application_status: 'enrollments.application_status',
    application_status_updated_on: 'enrollments.application_status_updated_on',
    international: 'enrollments.international',
    year_in_school: 'enrollments.year_in_school',
    anticipated_graduation_year: 'enrollments.anticipated_graduation_year',
    partner_program: 'enrollments.partner_program',
    application_fee_required: 'enrollments.application_fee_required',
    campyear: 'enrollments.campyear'
  }.freeze

  BATCH_ACTIONS = { destroy: 'Delete selected' }.freeze

  STATUS_OPTIONS = ['enrolled', 'application complete', 'offer accepted', 'offer declined', 'submitted'].freeze
  OFFER_STATUS_OPTIONS = %w[accepted declined offered].freeze

  def index
    @filter = Admin::ApplicationsFilter.new(params[Admin::Filter::PARAM_KEY])
    relation = @filter.apply(base_relation)
    @scope_counts = scope_counts(relation, SCOPES)
    relation = apply_scope(relation, SCOPES)
    relation = apply_sort(relation, allowed: SORTS, default: :updated_at, default_direction: :desc)
    relation = Admin::BalanceDueQuery.with_balance_due(relation)

    respond_to do |format|
      format.html { @pagy, @applications = paginate(relation) }
      format.csv { send_csv(csv_export, relation, filename: 'applications') }
    end
  end

  def show
    @payment_state = PaymentState.new(@application)
    @assigned_activities = Activity.where(camp_occurrence_id: @application.session_assignments.accepted.pluck(:camp_occurrence_id),
                                          id: @application.enrollment_activities.pluck(:activity_id))
                                   .includes(:camp_occurrence).order(:camp_occurrence_id)
  end

  def edit; end

  def update
    attributes = application_params
    withdrawing = params[:withdraw_enrollment].present? || attributes[:application_status] == 'withdrawn'

    if withdrawing && @application.application_status != 'withdrawn'
      released = @application.withdraw!(extra_attrs: attributes.to_h.symbolize_keys)
      redirect_to admin_application_path(@application), notice: withdrawal_notice(released), status: :see_other
    elsif @application.update(attributes)
      redirect_to admin_application_path(@application), notice: 'Application was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_content
  end

  def destroy
    @application.destroy
    redirect_to admin_applications_path, notice: 'Application was successfully deleted.', status: :see_other
  end

  def batch
    perform_batch_action(Enrollment.all, BATCH_ACTIONS, redirect_to_path: admin_applications_path)
  end

  # --- Member actions (the ActiveAdmin show-page "action items") ---

  def waitlist
    @application.transition_application_status!('waitlisted')
    redirect_to admin_application_path(@application), notice: 'Application was placed on waitlist.', status: :see_other
  end

  def remove_from_waitlist
    @application.transition_application_status!('application complete')
    redirect_to admin_application_path(@application), status: :see_other,
                notice: 'Application was removed from waitlist. Send an email to the applicant with further instructions.'
  end

  def withdraw
    released = @application.withdraw!
    redirect_to admin_application_path(@application), notice: withdrawal_notice(released), status: :see_other
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_application_path(@application), alert: e.record.errors.full_messages.to_sentence, status: :see_other
  end

  def send_finaid_request_email
    FinaidMailer.with(enrollment: @application).fin_aid_request_email.deliver_now
    redirect_to admin_application_path(@application), notice: 'Financial aid request link was sent to the applicant.', status: :see_other
  end

  private

  def set_application
    @application = Enrollment.includes(:user, :applicant_detail).find(params[:id])
  end

  def base_relation
    # preload (not includes): the index adds a computed select column, which eager_load would drop.
    Enrollment.left_joins(:applicant_detail).preload(:user, :applicant_detail)
  end

  def withdrawal_notice(released_assignments)
    notice = 'Enrollment has been withdrawn.'
    notice += " Deleted course assignment(s): #{released_assignments.join('; ')}" if released_assignments.any?
    notice
  end

  def application_params
    params.require(:enrollment).permit(
      :user_id, :international, :uniqname, :campyear,
      :high_school_name, :high_school_address1, :high_school_address2, :high_school_city,
      :high_school_state, :high_school_non_us, :high_school_postalcode, :high_school_country,
      :year_in_school, :anticipated_graduation_year, :room_mate_request, :personal_statement,
      :camp_doc_form_completed, :shirt_size, :notes, :application_status, :application_status_updated_on,
      :offer_status, :partner_program, :transcript, :student_packet, :application_deadline,
      :vaccine_record, :covid_test_record,
      session_assignments_attributes: %i[id camp_occurrence_id _destroy],
      course_assignments_attributes: %i[id course_id wait_list _destroy]
    )
  end

  def csv_export
    view = helpers
    Admin::CsvExport.define do
      column :updated_at
      column('Name') { |app| app.applicant_detail&.full_name }
      column('email') { |app| app.user.email }
      column('Transcript') { |app| 'uploaded' if app.transcript.attached? }
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
      column('Balance Due') { |app| view.admin_money_from_cents(app.balance_due_cents) }
      column('Camp Year') { |app| app.campyear }
    end
  end
end
