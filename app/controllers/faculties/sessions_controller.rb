# frozen_string_literal: true

class Faculties::SessionsController < Devise::SessionsController

  # POST /resource/sign_in
  def create
    faculty = Faculty.find_by(email: params[:faculty][:email].downcase)
    if faculty 
      uniqname = faculty.email.split('@').first
      if Course.current_camp.pluck(:faculty_uniqname).uniq.compact.include?(uniqname)
        sign_in faculty
        # Set session creation time for accurate expiry calculation
        session[:session_created_at] = Time.current.to_i
        redirect_to faculty_path
      else
        redirect_to root_path, :alert => "You don't have any courses, please contact the administrator"
      end
    else
      redirect_to new_faculty_session_path, :alert => "Please sign up first!"
    end
  end

  # DELETE /resource/sign_out
  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message! :notice, :signed_out if signed_out
    yield if block_given?
    respond_to_on_destroy
  end

  private

    def respond_to_on_destroy
      # We actually need to hardcode this as Rails default responder doesn't
      # support returning empty response on GET request
      respond_to do |format|
        format.all { head :no_content }
        format.any(*navigational_formats) { redirect_to faculty_login_path }
      end
    end

end
