# frozen_string_literal: true

class CoursePreferencesController < ApplicationController
  devise_group :logged_in, contains: [:user, :admin]
  before_action :authenticate_logged_in!
  
  before_action :set_current_enrollment
  before_action :course_preference, only: [ :edit, :create, :update, :new, :destroy ]

  def index
    @current_enrollment_course_preferences_all = @current_enrollment.course_preferences
    @current_enrollment_session1 = @current_enrollment.session_registrations.find_by(description: "Session 1")
    @current_enrollment_session2 = @current_enrollment.session_registrations.find_by(description: "Session 2")
    @current_enrollment_session3 = @current_enrollment.session_registrations.find_by(description: "Session 3")
 
    @current_enrollment_session1_courses = @current_enrollment.course_registrations.where(camp_occurrence: @current_enrollment_session1)
    @current_enrollment_session2_courses = @current_enrollment.course_registrations.where(camp_occurrence: @current_enrollment_session2)
    @current_enrollment_session3_courses = @current_enrollment.course_registrations.where(camp_occurrence: @current_enrollment_session3)
  end

  def show
    @course_pref = CoursePreference.find(params[:id])
    @course_info = Course.find_by(id: @course_pref.course_id )
  end

  def new
    @course_preference = CoursePreference.new
    @current_enrollment_session1 = @current_enrollment.session_registrations.find_by(description: "Session 1")
    @current_enrollment_session1_courses = @current_enrollment.course_registrations.where(camp_occurrence: @current_enrollment_session1)
    @current_enrollment_session2 = @current_enrollment.session_registrations.find_by(description: "Session 2")
    @current_enrollment_session2_courses = @current_enrollment.course_registrations.where(camp_occurrence: @current_enrollment_session2)
    @current_enrollment_session3 = @current_enrollment.session_registrations.find_by(description: "Session 3")
    @current_enrollment_session3_courses = @current_enrollment.course_registrations.where(camp_occurrence: @current_enrollment_session3)
  end

  def create
    @course_preference = CoursePreference.new(cp_params)

    respond_to do |format|
      if @course_preference.save
        format.html { redirect_to enrollment_course_preferences_path(@current_enrollment), notice: 'Course Preference was successfully edited.' }
        format.json { render :show, status: :created, location: @course_preference }
      else
        format.html { render :new }
        format.json { render json: @course_preference.errors, status: :unprocessable_entity }
      end
    end

  end

  def edit
    @course_preference = @current_enrollment.course_preferences.find(params[:id])
    @course_camp = @course_preference.course.camp_occurrence
    @remaining_selections = get_rankings_available(@course_camp)
  end

  def update
    @course_preference = @current_enrollment.course_preferences.find(params[:id])
    respond_to do |format|
      if  @course_preference.update(cp_params)
        if @current_enrollment.course_preferences.pluck(:ranking).any?{ |e| e.nil? }
          format.html { redirect_to course_preferences_path, notice: 'Course Preference was successfully updated.' }
          format.json { render :show, status: :ok, location: course_preferences_path }
        else
          format.html { redirect_to root_path, notice: 'Course Preference was successfully updated.' }
          format.json { render :show, status: :ok, location: root_path }
        end
      else
        format.html { render :edit }
        format.json { render json: @course_preference.errors, status: :unprocessable_entity }
      end
    end
  end

  private

    def set_current_enrollment
      @current_enrollment = current_user.enrollments.current_camp_year_applications.last
    end

    def course_preference
      @course_preference = @current_enrollment.course_preferences.find(params[:id])
    end

    def get_rankings_available(camp_occurrence)
      ids = @current_enrollment.course_registrations.where(camp_occurrence: camp_occurrence).pluck(:id)
      selections_used =  @current_enrollment.course_preferences.where(course_id: ids).pluck(:ranking).compact
      if selections_used.empty?
        (1..12).to_a
      else
        (1..12).to_a - selections_used
      end
    end

    def cp_params
      params.require(:course_preference).permit(:course_preference,:course_id, :ranking)
    end
end
