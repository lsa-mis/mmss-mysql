# frozen_string_literal: true

class Admin::SessionAssignmentsController < Admin::BaseController
  before_action :set_session_assignment, only: %i[show edit update destroy]

  SCOPES = [
    Admin::Scope.new(:current_year_session_assignments, label: 'Current years Session Assignments', default: true),
    Admin::Scope.new(:all, label: 'All'),
    Admin::Scope.new(:accepted, group: :offer_status)
  ].freeze

  SORTS = {
    enrollment: 'applicant_details.lastname',
    session: 'camp_occurrences.description',
    offer_status: 'session_assignments.offer_status',
    created_at: 'session_assignments.created_at',
    updated_at: 'session_assignments.updated_at'
  }.freeze

  BATCH_ACTIONS = { destroy: 'Delete selected' }.freeze

  OFFER_STATUS_OPTIONS = %w[accepted declined].freeze

  CSV_EXPORT = Admin::CsvExport.define do
    column('Name') { |assignment| assignment.enrollment.applicant_detail&.full_name }
    column('email') { |assignment| assignment.enrollment.user.email }
    column('Session') { |assignment| assignment.camp_occurrence.display_name }
  end

  def index
    @filter = Admin::SessionAssignmentsFilter.new(params[Admin::Filter::PARAM_KEY])
    relation = @filter.apply(base_relation)
    @scope_counts = scope_counts(relation, SCOPES)
    relation = apply_scope(relation, SCOPES)
    relation = apply_sort(relation, allowed: SORTS, default: :created_at, default_direction: :desc)

    respond_to do |format|
      format.html { @pagy, @session_assignments = paginate(relation) }
      format.csv { send_csv(CSV_EXPORT, relation, filename: 'session-assignments') }
    end
  end

  def show; end

  def new
    @session_assignment = SessionAssignment.new
  end

  def create
    @session_assignment = SessionAssignment.new(session_assignment_params)

    if @session_assignment.save
      redirect_to admin_session_assignment_path(@session_assignment), notice: 'Session assignment was successfully created.',
                                                                     status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @session_assignment.update(session_assignment_params)
      redirect_to admin_session_assignment_path(@session_assignment), notice: 'Session assignment was successfully updated.',
                                                                     status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @session_assignment.destroy
    redirect_to admin_session_assignments_path, notice: 'Session assignment was successfully deleted.', status: :see_other
  end

  def batch
    perform_batch_action(SessionAssignment.all, BATCH_ACTIONS, redirect_to_path: admin_session_assignments_path)
  end

  private

  def set_session_assignment
    @session_assignment = SessionAssignment.includes(:camp_occurrence, enrollment: %i[user applicant_detail]).find(params[:id])
  end

  def base_relation
    SessionAssignment.left_joins(:camp_occurrence).left_joins(enrollment: :applicant_detail)
                     .preload(:camp_occurrence, enrollment: %i[user applicant_detail])
  end

  def session_assignment_params
    params.require(:session_assignment).permit(:enrollment_id, :camp_occurrence_id, :offer_status)
  end
end
