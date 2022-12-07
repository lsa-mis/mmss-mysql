class FacultiesController < ApplicationController
  before_action :authenticate_faculty!

  def index
    faculty = current_faculty.email.split('@').first
    @courses = Course.where(faculty_uniqname: faculty)

  end

end
