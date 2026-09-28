# frozen_string_literal: true

# Rejections: saving one destroys the application's course/session assignments, moves it to
# `rejected` and emails the applicant (Rejection#set_rejection_status, an after_create_commit callback).
# The status transition is checked up front so a rejection is never recorded for an application
# that cannot be rejected (enrolled/withdrawn), which would otherwise fail after the commit.
class Admin::RejectionsController < Admin::BaseController
  before_action :set_rejection, only: %i[show edit update destroy]

  SORTS = {
    id: 'rejections.id',
    enrollment: 'applicant_details.lastname',
    created_at: 'rejections.created_at',
    updated_at: 'rejections.updated_at'
  }.freeze

  BATCH_ACTIONS = { destroy: 'Delete selected' }.freeze

  CSV_EXPORT = Admin::CsvExport.define do
    column :id
    column('Name') { |rejection| rejection.enrollment.applicant_detail&.full_name }
    column('email') { |rejection| rejection.enrollment.user.email }
    column :reason
    column :created_at
    column :updated_at
  end

  def index
    @filter = Admin::RejectionsFilter.new(params[Admin::Filter::PARAM_KEY])
    relation = @filter.apply(base_relation)
    relation = apply_sort(relation, allowed: SORTS, default: :created_at, default_direction: :desc)

    respond_to do |format|
      format.html { @pagy, @rejections = paginate(relation) }
      format.csv { send_csv(CSV_EXPORT, relation, filename: 'rejections') }
    end
  end

  def show; end

  # Entry point from the application's "Reject Applicant" action: ?enrollment_id= prefills the
  # applicant and the form shows the name instead of the select.
  def new
    @rejection = Rejection.new
    @rejection.enrollment = Enrollment.find_by(id: params[:enrollment_id]) if params[:enrollment_id].present?
  end

  def create
    @rejection = Rejection.new(rejection_params)

    if rejectable? && @rejection.save
      redirect_to admin_rejection_path(@rejection), notice: 'Rejection was recorded and the applicant has been notified.',
                                                   status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  # The enrollment is immutable once a rejection exists: reassigning it would leave the old
  # application rejected and reject a second one (the status change runs after commit).
  def update
    @rejection.assign_attributes(rejection_params.slice(:reason))

    if rejectable? && @rejection.save
      redirect_to admin_rejection_path(@rejection), notice: 'Rejection was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @rejection.destroy
    redirect_to admin_rejections_path, notice: 'Rejection was successfully deleted.', status: :see_other
  end

  def batch
    perform_batch_action(Rejection.all, BATCH_ACTIONS, redirect_to_path: admin_rejections_path)
  end

  private

  # The create commit runs the status transition; refuse up front when Enrollment's transition
  # rules would reject it (an existing rejection's application is already rejected, so this is
  # a no-op on update).
  def rejectable?
    enrollment = @rejection.enrollment
    return true if enrollment.nil? || enrollment.can_transition_application_status?('rejected')

    @rejection.errors.add(:base, "This application is #{enrollment.application_status} and cannot be rejected.")
    false
  end

  def set_rejection
    @rejection = Rejection.includes(enrollment: %i[user applicant_detail]).find(params[:id])
  end

  def base_relation
    Rejection.left_joins(enrollment: :applicant_detail).preload(enrollment: %i[user applicant_detail])
  end

  def rejection_params
    params.require(:rejection).permit(:enrollment_id, :reason)
  end
end
