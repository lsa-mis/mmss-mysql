# frozen_string_literal: true

# Session Selections = SessionActivity records (the sessions an applicant registered for). The
# ActiveAdmin resource was registered `as: 'Session Selection'`, so the routes keep that name.
class Admin::SessionSelectionsController < Admin::BaseController
  before_action :set_session_selection, only: %i[show edit update destroy]

  SORTS = {
    enrollment: 'applicant_details.lastname',
    session: 'camp_occurrences.description',
    created_at: 'session_activities.created_at',
    updated_at: 'session_activities.updated_at'
  }.freeze

  BATCH_ACTIONS = { destroy: 'Delete selected' }.freeze

  CSV_EXPORT = Admin::CsvExport.define do
    column :id
    column('Name') { |selection| selection.enrollment.applicant_detail&.full_name }
    column('email') { |selection| selection.enrollment.user.email }
    column('Session') { |selection| selection.camp_occurrence.display_name }
    column :created_at
    column :updated_at
  end

  def index
    @filter = Admin::SessionSelectionsFilter.new(params[Admin::Filter::PARAM_KEY])
    relation = @filter.apply(base_relation)
    relation = apply_sort(relation, allowed: SORTS, default: :created_at, default_direction: :desc)

    respond_to do |format|
      format.html { @pagy, @session_selections = paginate(relation) }
      format.csv { send_csv(CSV_EXPORT, relation, filename: 'session-selections') }
    end
  end

  def show; end

  def new
    @session_selection = SessionActivity.new
  end

  def create
    @session_selection = SessionActivity.new(session_selection_params)

    if @session_selection.save
      redirect_to admin_session_selection_path(@session_selection), notice: 'Session selection was successfully created.',
                                                                   status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @session_selection.update(session_selection_params)
      redirect_to admin_session_selection_path(@session_selection), notice: 'Session selection was successfully updated.',
                                                                   status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @session_selection.destroy
    redirect_to admin_session_selections_path, notice: 'Session selection was successfully deleted.', status: :see_other
  end

  def batch
    perform_batch_action(SessionActivity.all, BATCH_ACTIONS, redirect_to_path: admin_session_selections_path)
  end

  private

  def set_session_selection
    @session_selection = SessionActivity.includes(:camp_occurrence, enrollment: %i[user applicant_detail]).find(params[:id])
  end

  def base_relation
    SessionActivity.left_joins(:camp_occurrence).left_joins(enrollment: :applicant_detail)
                   .preload(:camp_occurrence, enrollment: %i[user applicant_detail])
  end

  def session_selection_params
    params.require(:session_activity).permit(:enrollment_id, :camp_occurrence_id)
  end
end
