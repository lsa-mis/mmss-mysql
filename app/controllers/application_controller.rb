# frozen_string_literal: true

class ApplicationController < ActionController::Base
  def after_sign_in_path_for(resource)
    if faculty_signed_in?
      faculty_path
    elsif admin_signed_in?
      admin_root_path
    else
      root_path
    end
  end

end
