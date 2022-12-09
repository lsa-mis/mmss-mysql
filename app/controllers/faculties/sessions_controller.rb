# frozen_string_literal: true

class Faculties::SessionsController < Devise::SessionsController

  # GET /resource/sign_in
  def new
    super 
  end

  # POST /resource/sign_in
  def create
    faculty = Faculty.find_by(email: params[:faculty][:email].downcase)
    if faculty 
      uniqname = faculty.email.split('@').first
      if Course.current_camp.pluck(:faculty_uniqname).uniq.compact.include?(uniqname)
        sign_in_and_redirect faculty
      else
        redirect_to root_path, :alert => "You don't have any courses, please contact the administrator"
      end
    else
      redirect_to new_faculty_session_path, :alert => "Please sign up first!"
    end
  end

  # DELETE /resource/sign_out
  def destroy
    super
  end

end
