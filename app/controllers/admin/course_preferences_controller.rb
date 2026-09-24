# frozen_string_literal: true

class Admin::CoursePreferencesController < Admin::BaseController
  before_action :set_course_preference, only: %i[show edit update destroy]

  SORTS = {
    id: 'course_preferences.id',
    enrollment: 'applicant_details.lastname',
    session: 'camp_occurrences.description',
    course: 'courses.title',
    ranking: 'course_preferences.ranking',
    created_at: 'course_preferences.created_at',
    updated_at: 'course_preferences.updated_at'
  }.freeze

  BATCH_ACTIONS = { destroy: 'Delete selected' }.freeze

  RANKINGS = (1..CoursePreference::MAX_RANKING).to_a.freeze

  CSV_EXPORT = Admin::CsvExport.define do
    column :id
    column('Name') { |preference| preference.enrollment.applicant_detail&.full_name }
    column('email') { |preference| preference.enrollment.user.email }
    column('Session') { |preference| preference.course.camp_occurrence.description }
    column('Course') { |preference| preference.course.title }
    column :ranking
    column :created_at
    column :updated_at
  end

  def index
    @filter = Admin::CoursePreferencesFilter.new(params[Admin::Filter::PARAM_KEY])
    relation = @filter.apply(base_relation)
    relation = apply_sort(relation, allowed: SORTS, default: :id, default_direction: :desc)

    respond_to do |format|
      format.html { @pagy, @course_preferences = paginate(relation) }
      format.csv { send_csv(CSV_EXPORT, relation, filename: 'course-preferences') }
    end
  end

  def show; end

  def new
    @course_preference = CoursePreference.new
  end

  def create
    @course_preference = CoursePreference.new(course_preference_params)

    if @course_preference.save
      redirect_to admin_course_preference_path(@course_preference), notice: 'Course preference was successfully created.',
                                                                   status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @course_preference.update(course_preference_params)
      redirect_to admin_course_preference_path(@course_preference), notice: 'Course preference was successfully updated.',
                                                                   status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @course_preference.destroy
    redirect_to admin_course_preferences_path, notice: 'Course preference was successfully deleted.', status: :see_other
  end

  def batch
    perform_batch_action(CoursePreference.all, BATCH_ACTIONS, redirect_to_path: admin_course_preferences_path)
  end

  private

  def set_course_preference
    @course_preference = CoursePreference.includes(enrollment: %i[user applicant_detail], course: :camp_occurrence).find(params[:id])
  end

  def base_relation
    CoursePreference.left_joins(course: :camp_occurrence).left_joins(enrollment: :applicant_detail)
                    .preload(enrollment: %i[user applicant_detail], course: :camp_occurrence)
  end

  def course_preference_params
    params.require(:course_preference).permit(:enrollment_id, :course_id, :ranking)
  end
end
