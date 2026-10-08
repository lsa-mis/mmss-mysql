# frozen_string_literal: true

# Applicant-facing application form (one enrollment per camp year). The admin listing, status
# changes and deletion live in Admin::ApplicationsController.
class EnrollmentsController < ApplicationController
  include ApplicantState

  before_action :authenticate_user!

  before_action :set_current_enrollment, only: [:show, :edit, :update]
  before_action :set_course_sessions
  before_action :set_activities_sessions

  # GET /enrollments/1
  def show
    @registration_activities = @current_enrollment.registration_activities.order(camp_occurrence_id: :asc)
    @session_registrations = @current_enrollment.session_registrations.order(description: :asc)
    @course_registrations = @current_enrollment.course_registrations.order(camp_occurrence_id: :asc)
    @room_mate = get_room_mate
  end

  # GET /enrollments/new
  def new
    @enrollment = Enrollment.new
  end

  # GET /enrollments/1/edit
  def edit
  end

  # POST /enrollments
  def create
    @enrollment = current_user.enrollments.create(enrollment_params)

    if @enrollment.save
      if @enrollment.course_rankings_complete?
        redirect_to root_path, notice: 'Application was successfully created.', status: :see_other
      else
        redirect_to enrollment_course_preferences_path(@enrollment),
                    notice: 'Application was saved. Next, rank the courses you selected for each session (1 = highest interest).', status: :see_other
      end
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /enrollments/1
  def update
    if @current_enrollment.update(enrollment_params)
      @current_enrollment.auto_enroll_if_ready!
      if @current_enrollment.course_rankings_complete?
        redirect_to root_path, notice: 'Application was successfully updated.', status: :see_other
      else
        redirect_to enrollment_course_preferences_path(@current_enrollment),
                    notice: 'Application was updated. When you are ready, rank the courses you selected for each session.', status: :see_other
      end
    elsif @current_enrollment.errors.include?(:student_packet) || @current_enrollment.errors.include?(:vaccine_record) || @current_enrollment.errors.include?(:covid_test_record)
      redirect_to root_path, alert: @current_enrollment.errors.full_messages.to_sentence, status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_current_enrollment
      @current_enrollment = current_user.enrollments.current_camp_year_applications.last
      return if @current_enrollment.present?
      redirect_to root_path, alert: "No current enrollment found.", status: :see_other
    end

    def set_course_sessions
      CampOccurrence.active.each do |ca|
        if ca.description == "Session 1"
          @courses_session1 = ca.courses.is_open.order(title: :asc)
        end
        if ca.description == "Session 2"
          @courses_session2 = ca.courses.is_open.order(title: :asc)
        end
        if ca.description == "Session 3"
          @courses_session3 = ca.courses.is_open.order(title: :asc)
        end
      end
    end

    def set_activities_sessions
      CampOccurrence.active.each do |as|
        if as.description == "Session 1"
          @activities_session1 = as.activities.active.order(description: :asc)
        end
        if as.description == "Session 2"
          @activities_session2 = as.activities.active.order(description: :asc)
        end
        if as.description == "Session 3"
          @activities_session3 = as.activities.active.order(description: :asc)
        end
      end
    end

    def get_room_mate
      unless @current_enrollment.room_mate_request.blank?
        "I want to room with #{@current_enrollment.room_mate_request}."
      else
        "No specific room mate requested"
      end
    end

    # The owner is always current_user (create goes through current_user.enrollments) and the
    # admin-only columns (notes, application/offer status, partner program) are set through
    # Admin::ApplicationsController, so none of them is accepted here.
    def enrollment_params
      params.require(:enrollment).permit(
                          :international, :high_school_name,
                          :high_school_address1, :high_school_address2,
                          :high_school_city, :high_school_state,
                          :high_school_non_us, :high_school_postalcode,
                          :high_school_country, :year_in_school,
                          :anticipated_graduation_year, :room_mate_request,
                          :personal_statement, :shirt_size, :transcript,
                          :student_packet, :campyear, :camp_doc_form_completed,
                          :vaccine_record, :covid_test_record,
                          registration_activity_ids: [],
                          session_registration_ids: [],
                          course_registration_ids: [])
    end
end
