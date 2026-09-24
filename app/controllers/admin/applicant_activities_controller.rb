# frozen_string_literal: true

# Applicant Activities = EnrollmentActivity records (activities an applicant selected). The
# ActiveAdmin resource was registered `as: 'Applicant Activities'`, so the routes keep that name.
class Admin::ApplicantActivitiesController < Admin::BaseController
  before_action :set_applicant_activity, only: %i[show edit update destroy]

  SORTS = {
    id: 'enrollment_activities.id',
    enrollment: 'applicant_details.lastname',
    activity: 'activities.description',
    session: 'camp_occurrences.description',
    created_at: 'enrollment_activities.created_at',
    updated_at: 'enrollment_activities.updated_at'
  }.freeze

  BATCH_ACTIONS = { destroy: 'Delete selected' }.freeze

  CSV_EXPORT = Admin::CsvExport.define do
    column('Name') { |record| record.enrollment.applicant_detail&.full_name }
    column('email') { |record| record.enrollment.user.email }
    column('Activity') { |record| record.activity.description }
    column('Session') { |record| record.activity.camp_occurrence.display_name }
  end

  def index
    @filter = Admin::ApplicantActivitiesFilter.new(params[Admin::Filter::PARAM_KEY])
    relation = @filter.apply(base_relation)
    relation = apply_sort(relation, allowed: SORTS, default: :id, default_direction: :desc)

    respond_to do |format|
      format.html { @pagy, @applicant_activities = paginate(relation) }
      format.csv { send_csv(CSV_EXPORT, relation, filename: 'applicant-activities') }
    end
  end

  def show; end

  def new
    @applicant_activity = EnrollmentActivity.new
  end

  def create
    @applicant_activity = EnrollmentActivity.new(applicant_activity_params)

    if @applicant_activity.save
      redirect_to admin_applicant_activity_path(@applicant_activity), notice: 'Applicant activity was successfully created.',
                                                                     status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @applicant_activity.update(applicant_activity_params)
      redirect_to admin_applicant_activity_path(@applicant_activity), notice: 'Applicant activity was successfully updated.',
                                                                     status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @applicant_activity.destroy
    redirect_to admin_applicant_activities_path, notice: 'Applicant activity was successfully deleted.', status: :see_other
  end

  def batch
    perform_batch_action(EnrollmentActivity.all, BATCH_ACTIONS, redirect_to_path: admin_applicant_activities_path)
  end

  private

  def set_applicant_activity
    @applicant_activity = EnrollmentActivity.includes(enrollment: %i[user applicant_detail], activity: :camp_occurrence).find(params[:id])
  end

  def base_relation
    EnrollmentActivity.left_joins(activity: :camp_occurrence).left_joins(enrollment: :applicant_detail)
                      .preload(enrollment: %i[user applicant_detail], activity: :camp_occurrence)
  end

  def applicant_activity_params
    params.require(:enrollment_activity).permit(:enrollment_id, :activity_id)
  end
end
