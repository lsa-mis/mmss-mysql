# frozen_string_literal: true

class FacultiesController < ApplicationController
  layout 'faculty'
  before_action :authenticate_faculty!
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  def index
    faculty = current_faculty.email.split('@').first
    @courses = Course.current_camp.where(faculty_uniqname: faculty)

  end

  def student_list
    @course = Course.find(params[:id])
    enrollment_ids = CourseAssignment.where(course_id: params[:id], wait_list: false).pluck(:enrollment_id)
    @students = Enrollment.where(id: enrollment_ids)
  end

  def student_page
    @student = Enrollment.find(params[:id])

  end

  private

  def render_not_found
    head :not_found
  end
end
