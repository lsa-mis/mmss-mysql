class ApplicationController < ActionController::Base
  def after_sign_in_path_for(resource)
    if faculty_signed_in?
      faculties_path
      # uniqname = current_faculty.email.split('@').first
      # if Course.current_camp.pluck(:faculty_uniqname).uniq.compact.include?(uniqname)
      #   faculty_path
      # else
      #   flash.now[:alert] = "hell"
      #   destroy_faculty_session_path
      # end
    elsif admin_signed_in?
      admin_root_path
    else
      root_path
    end
  end

end
