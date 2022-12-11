class FacultiesController < ApplicationController
  before_action :authenticate_faculty!

  def index
    faculty = current_faculty.email.split('@').first
    @courses = Course.current_camp.where(faculty_uniqname: faculty)

  end

  def student_list
    @course = Course.find(params[:id])
    enrollment_ids = CourseAssignment.where(course_id: params[:id]).pluck(:enrollment_id)
    @students = Enrollment.where(id: enrollment_ids)
    render layout: 'student_list'
  end

end
