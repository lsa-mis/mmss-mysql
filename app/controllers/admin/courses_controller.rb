# frozen_string_literal: true

class Admin::CoursesController < Admin::BaseController
  before_action :set_course, only: %i[show edit update destroy]

  SCOPES = [
    Admin::Scope.new(:current_camp, label: 'Current Camp Courses', default: true),
    Admin::Scope.new(:all, label: 'All')
  ].freeze

  SORTS = {
    session: 'camp_occurrences.description',
    title: 'courses.title',
    available_spaces: 'courses.available_spaces',
    faculty_uniqname: 'courses.faculty_uniqname',
    faculty_name: 'courses.faculty_name',
    status: 'courses.status',
    created_at: 'courses.created_at',
    updated_at: 'courses.updated_at'
  }.freeze

  BATCH_ACTIONS = { destroy: 'Delete selected', toggle_status: 'Toggle open/closed' }.freeze

  CSV_EXPORT = Admin::CsvExport.define do
    column :id
    column('Session') { |course| course.camp_occurrence.description }
    column :title
    column :available_spaces
    column('Open spaces', &:remaining_spaces)
    column('Wait list') { |course| CourseAssignment.wait_list_number(course.id) }
    column :status
    column :faculty_uniqname
    column :faculty_name
    column :created_at
    column :updated_at
  end

  def index
    @filter = Admin::CoursesFilter.new(params[Admin::Filter::PARAM_KEY])
    relation = @filter.apply(Course.joins(:camp_occurrence).includes(:camp_occurrence))
    @scope_counts = scope_counts(relation, SCOPES)
    relation = apply_scope(relation, SCOPES)
    relation = apply_sort(relation, allowed: SORTS, default: :title)

    respond_to do |format|
      format.html { @pagy, @courses = paginate(relation) }
      format.csv { send_csv(CSV_EXPORT, relation, filename: 'courses') }
    end
  end

  def show
    @course_assignments = @course.course_assignments
                                 .includes(enrollment: %i[user applicant_detail])
                                 .order(:wait_list, :id)
  end

  def new
    @course = Course.new(status: 'open')
  end

  def create
    @course = Course.new(course_params)

    if @course.save
      redirect_to admin_course_path(@course), notice: 'Course was successfully created.', status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @course.update(course_params)
      redirect_to admin_course_path(@course), notice: 'Course was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @course.destroy
    redirect_to admin_courses_path, notice: 'Course was successfully deleted.', status: :see_other
  end

  def batch
    perform_batch_action(Course.all, BATCH_ACTIONS, redirect_to_path: admin_courses_path)
  end

  private

  def batch_toggle_status(records)
    toggled = records.to_a.count { |course| course.update(status: course.status == 'open' ? 'closed' : 'open') }
    "Toggled status for #{toggled} #{'course'.pluralize(toggled)}."
  end

  def set_course
    @course = Course.includes(:camp_occurrence).find(params[:id])
  end

  def course_params
    params.require(:course).permit(:camp_occurrence_id, :title, :available_spaces, :status, :faculty_uniqname, :faculty_name)
  end
end
