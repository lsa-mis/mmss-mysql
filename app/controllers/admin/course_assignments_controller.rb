# frozen_string_literal: true

class Admin::CourseAssignmentsController < Admin::BaseController
  before_action :set_course_assignment, only: %i[show edit update destroy]

  SORTS = {
    enrollment: 'applicant_details.lastname',
    course: 'courses.title',
    wait_list: 'course_assignments.wait_list',
    created_at: 'course_assignments.created_at',
    updated_at: 'course_assignments.updated_at'
  }.freeze

  BATCH_ACTIONS = { destroy: 'Delete selected' }.freeze

  CSV_EXPORT = Admin::CsvExport.define do
    column('Name') { |assignment| assignment.enrollment.applicant_detail&.full_name }
    column('email') { |assignment| assignment.enrollment.user.email }
    column('Course') { |assignment| assignment.course.title }
    column('Session') { |assignment| assignment.course.camp_occurrence.display_name }
  end

  def index
    @filter = Admin::CourseAssignmentsFilter.new(params[Admin::Filter::PARAM_KEY])
    relation = @filter.apply(base_relation)
    relation = apply_sort(relation, allowed: SORTS, default: :created_at, default_direction: :desc)

    respond_to do |format|
      format.html { @pagy, @course_assignments = paginate(relation) }
      format.csv { send_csv(CSV_EXPORT, relation, filename: 'course-assignments') }
    end
  end

  def show; end

  def new
    @course_assignment = CourseAssignment.new
  end

  def create
    @course_assignment = CourseAssignment.new(course_assignment_params)

    if @course_assignment.save
      redirect_to admin_course_assignment_path(@course_assignment), notice: 'Course assignment was successfully created.',
                                                                   status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @course_assignment.update(course_assignment_params)
      redirect_to admin_course_assignment_path(@course_assignment), notice: 'Course assignment was successfully updated.',
                                                                   status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @course_assignment.destroy
    redirect_to admin_course_assignments_path, notice: 'Course assignment was successfully deleted.', status: :see_other
  end

  def batch
    perform_batch_action(CourseAssignment.all, BATCH_ACTIONS, redirect_to_path: admin_course_assignments_path)
  end

  private

  def set_course_assignment
    @course_assignment = CourseAssignment.includes(enrollment: %i[user applicant_detail], course: :camp_occurrence).find(params[:id])
  end

  def base_relation
    CourseAssignment.left_joins(:course, enrollment: :applicant_detail)
                    .preload(enrollment: %i[user applicant_detail], course: :camp_occurrence)
  end

  def course_assignment_params
    params.require(:course_assignment).permit(:enrollment_id, :course_id, :wait_list)
  end
end
