# frozen_string_literal: true

class StaticPagesController < ApplicationController
  include ApplicantState
  # devise_group :logged_in, contains: [:user, :admin]
  # before_action :authenticate_logged_in!, except: [:contact :privacy]
  # before_action :authenticate_admin!, only: [:destroy]
  before_action :set_current_enrollment

  def index
    if faculty_signed_in?
      redirect_to faculty_path
    end
    @application_materials_due_date = CampConfiguration.active_camp_materials_due_date
    @active_camp_exists = CampConfiguration.active.exists?
    @current_camp_year = CampConfiguration.active_camp_year
  end

  def contact
  end

  def privacy
  end

  def faculty_login
  end

  private
    def set_current_enrollment
      if user_signed_in?
        @current_enrollment = current_user.enrollments.current_camp_year_applications.last
      end
    end

end
