# frozen_string_literal: true

# Applications = Enrollment records (the ActiveAdmin resource was registered `as: 'Application'`).
# Reference implementation for porting resources: filters, scopes, sorting, pagination, CSV,
# batch actions, comments and a custom update flow (withdrawal).
class Admin::ApplicationsController < Admin::BaseController
  before_action :set_application, only: %i[show edit update destroy]

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

  def new
    @application = Enrollment.new(campyear: CampConfiguration.active_camp_year)
  end

  def create
    @application = Enrollment.new(application_params)

    if @application.save
      redirect_to admin_application_path(@application), notice: 'Application was successfully created.', status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    attributes = application_params
    withdrawing = params[:withdraw_enrollment].present? || attributes[:application_status] == 'withdrawn'

    if withdrawing && @application.application_status != 'withdrawn'
      withdraw(attributes)
    elsif @application.update(attributes)
      redirect_to admin_application_path(@application), notice: 'Application was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @application.destroy
    redirect_to admin_applications_path, notice: 'Application was successfully deleted.', status: :see_other
  end

  def batch
    perform_batch_action(Enrollment.all, BATCH_ACTIONS, redirect_to_path: admin_applications_path)
  end

  private

  def set_application
    @application = Enrollment.includes(:user, :applicant_detail).find(params[:id])
  end

  def base_relation
    Enrollment.left_joins(:applicant_detail).includes(:user, :applicant_detail)
  end

  # Withdrawing removes every course assignment (they free up seats) and records what was removed
  # in the flash, matching the behaviour of EnrollmentsController#withdraw.
  def withdraw(attributes)
    deleted = @application.course_assignments.includes(course: :camp_occurrence).map do |assignment|
      "Course: #{assignment.course.title}, Session: #{assignment.course.camp_occurrence.description}"
    end
    @application.course_assignments.destroy_all

    attributes = attributes.merge(application_status: 'withdrawn', application_status_updated_on: Date.current)
    attributes.delete(:course_assignments_attributes)

    if @application.update(attributes)
      notice = 'Enrollment has been withdrawn.'
      notice += " Deleted course assignment(s): #{deleted.join('; ')}" if deleted.any?
      redirect_to admin_application_path(@application), notice: notice, status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
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
      column('Balance Due') { |app| view.admin_money_from_cents(PaymentState.new(app).balance_due) }
      column('Camp Year') { |app| app.campyear }
    end
  end
end
