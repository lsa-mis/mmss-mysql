# frozen_string_literal: true

class CoursePreferencesController < ApplicationController
  devise_group :logged_in, contains: [:user, :admin]
  before_action :authenticate_logged_in!

  before_action :set_current_enrollment, except: [:show]
  before_action :prepare_show, only: [:show]
  before_action :course_preference, only: %i[create update new destroy]

  def index
    load_course_preference_sessions
  end

  def show; end

  def new
    @course_preference = CoursePreference.new
    @current_enrollment_session1 = @current_enrollment.session_registrations.find_by(description: 'Session 1')
    @current_enrollment_session1_courses = @current_enrollment.course_registrations.where(camp_occurrence: @current_enrollment_session1)
    @current_enrollment_session2 = @current_enrollment.session_registrations.find_by(description: 'Session 2')
    @current_enrollment_session2_courses = @current_enrollment.course_registrations.where(camp_occurrence: @current_enrollment_session2)
    @current_enrollment_session3 = @current_enrollment.session_registrations.find_by(description: 'Session 3')
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
    redirect_to enrollment_course_preferences_path(@current_enrollment),
                notice: 'Rank all of your selected courses on one page. Drag courses to reorder, or use the rank menus, then click Save rankings.'
  end

  def bulk_update
    unless @current_enrollment.course_rankings_editable?
      redirect_to enrollment_course_preferences_path(@current_enrollment),
                  alert: 'Course rankings cannot be changed after your application has been processed.'
      return
    end

    rankings = bulk_rankings_params
    allowed_ids = @current_enrollment.course_preferences.pluck(:id).map(&:to_s).to_set
    if rankings.blank? || rankings.keys.to_set != allowed_ids || rankings.values.any?(&:blank?)
      load_course_preference_sessions
      flash.now[:alert] = 'Please choose a rank for every selected course.'
      render :index, status: :unprocessable_entity
      return
    end

    prefs = @current_enrollment.course_preferences.includes(:course).order(:id).to_a

    begin
      CoursePreference.transaction do
        prefs.each do |cp|
          cp.update!(ranking: rankings[cp.id.to_s].to_s.to_i)
        end
      end
      redirect_to root_path, notice: 'Course rankings were successfully saved.'
    rescue ActiveRecord::RecordInvalid => e
      load_course_preference_sessions
      flash.now[:alert] = e.record.errors.full_messages.to_sentence.presence ||
        'Unable to save rankings. Each session needs unique ranks within the allowed range.'
      render :index, status: :unprocessable_entity
    end
  end

  def update
    @course_preference = @current_enrollment.course_preferences.find(params[:id])
    respond_to do |format|
      if @course_preference.update(cp_params)
        if !@current_enrollment.reload.course_rankings_complete?
          format.html { redirect_to course_preferences_path, notice: 'Course Preference was successfully updated.' }
          format.json { render :show, status: :ok, location: course_preferences_path }
        else
          format.html { redirect_to root_path, notice: 'Course Preference was successfully updated.' }
          format.json { render :show, status: :ok, location: root_path }
        end
      else
        @course_camp = @course_preference.course.camp_occurrence
        @remaining_selections = get_rankings_available(@course_camp)
        format.html { render :edit }
        format.json { render json: @course_preference.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def prepare_show
    @course_pref = CoursePreference.find(params[:id])
    if @course_pref.enrollment.user_id != current_user.id
      redirect_to root_path, alert: 'Not authorized.'
      return
    end

    @course_info = @course_pref.course
    @current_enrollment = @course_pref.enrollment
  end

  def set_current_enrollment
    @current_enrollment = enrollment_from_params_or_current_year
    return if @current_enrollment.present?

    redirect_to root_path, alert: 'No current enrollment found.'
    return
  end

  def enrollment_from_params_or_current_year
    if params[:enrollment_id].present?
      current_user.enrollments.find_by(id: params[:enrollment_id])
    else
      current_user.enrollments.current_camp_year_applications.last
    end
  end

  def load_course_preference_sessions
    @current_enrollment_course_preferences_all = @current_enrollment.course_preferences.includes(course: :camp_occurrence)
    @current_enrollment_session1 = @current_enrollment.session_registrations.find_by(description: 'Session 1')
    @current_enrollment_session2 = @current_enrollment.session_registrations.find_by(description: 'Session 2')
    @current_enrollment_session3 = @current_enrollment.session_registrations.find_by(description: 'Session 3')

    @current_enrollment_session1_courses = @current_enrollment.course_registrations.where(camp_occurrence: @current_enrollment_session1)
    @current_enrollment_session2_courses = @current_enrollment.course_registrations.where(camp_occurrence: @current_enrollment_session2)
    @current_enrollment_session3_courses = @current_enrollment.course_registrations.where(camp_occurrence: @current_enrollment_session3)

    @ranking_sessions = [
      { label: 'Session 1', session: @current_enrollment_session1, courses: @current_enrollment_session1_courses },
      { label: 'Session 2', session: @current_enrollment_session2, courses: @current_enrollment_session2_courses },
      { label: 'Session 3', session: @current_enrollment_session3, courses: @current_enrollment_session3_courses }
    ].filter_map do |row|
      next if row[:session].blank? || row[:courses].blank?

      preferences = row[:courses].map do |course|
        @current_enrollment_course_preferences_all.find { |cp| cp.course_id == course.id }
      end.compact.sort_by { |cp| [cp.ranking || CoursePreference::MAX_RANKING + 1, course_title_for(cp)] }

      max_rank = [[preferences.size, CoursePreference::MAX_RANKING].max, 99].min

      { label: row[:label], session: row[:session], preferences: preferences, max_rank: max_rank }
    end
  end

  def course_title_for(course_preference)
    course_preference.course&.title.to_s
  end

  def course_preference
    @course_preference = @current_enrollment.course_preferences.find(params[:id])
  end

  def get_rankings_available(camp_occurrence)
    ids = @current_enrollment.course_registrations.where(camp_occurrence: camp_occurrence).pluck(:id)
    selections_used = @current_enrollment.course_preferences.where(course_id: ids).pluck(:ranking).compact
    if selections_used.empty?
      (1..12).to_a
    else
      (1..12).to_a - selections_used
    end
  end

  def cp_params
    params.require(:course_preference).permit(:course_preference, :course_id, :ranking)
  end

  def bulk_rankings_params
    raw = params[:rankings]
    allowed = @current_enrollment.course_preferences.pluck(:id).map(&:to_s)
    return {} if allowed.empty?

    case raw
    when ActionController::Parameters
      raw.permit(*allowed).to_h
    when Hash
      raw.stringify_keys.slice(*allowed)
    else
      {}
    end
  end

end
