class EnrollmentsController < ApplicationController
  include ApplicantState

  devise_group :logged_in, contains: [:user, :admin]
  before_action :authenticate_logged_in!
  before_action :authenticate_admin!, only: [:index, :destroy]

  before_action :set_current_enrollment, only: [:show, :edit, :update, :destroy]
  before_action :set_course_sessions
  before_action :set_activities_sessions

  # GET /enrollments
  # GET /enrollments.json
  def index
    if admin_signed_in?
      @enrollments = Enrollment.all
    else
      redirect_to root_path
    end
  end

  # GET /enrollments/1
  # GET /enrollments/1.json
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
  # POST /enrollments.json
  def create
    @enrollment = current_user.enrollments.create(enrollment_params)

    respond_to do |format|
      if @enrollment.save
        format.html { redirect_to root_path, notice: 'Application was successfully created.' }
        format.json { render :show, status: :created, location: @enrollment }
      else
        format.html { render :new }
        format.json { render json: @enrollment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /enrollments/1
  # PATCH/PUT /enrollments/1.json
  def update
    respond_to do |format|
      if @current_enrollment.update(enrollment_params)
        if @current_enrollment.student_packet.attached? && balance_due == 0
          @current_enrollment.update!(application_status: "enrolled", application_status_updated_on: Date.today)
        end
        format.html { redirect_to root_path, notice: 'Application was successfully updated.' }
        format.json { render :show, status: :ok, location: @current_enrollment }
      else
        if @current_enrollment.errors.include?(:student_packet) || @current_enrollment.errors.include?(:vaccine_record) || @current_enrollment.errors.include?(:covid_test_record)
          format.html { redirect_to root_path, alert: @current_enrollment.errors.full_messages.to_sentence }
        else
          format.html { render :edit }
          format.json { render json: @current_enrollment.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # DELETE /enrollments/1
  # DELETE /enrollments/1.json
  def destroy
    @enrollment.destroy
    respond_to do |format|
      format.html { redirect_to enrollments_url, notice: 'Enrollment was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def add_to_waitlist
    @enrollment = Enrollment.find(params[:id])
    @enrollment.update(application_status: 'waitlisted', application_status_updated_on: Date.today)
    respond_to do |format|
      format.html { redirect_to admin_applications_path, notice: 'Application was placed on waitlist.' }
      format.json { head :no_content }
    end
  end

  def send_finaid_request_email
    @enrollment = Enrollment.find_by(id: params[:enrollment_id])
    FinaidMailer.with(enrollment: @enrollment).fin_aid_request_email.deliver_now
    respond_to do |format|
      format.html { redirect_to admin_application_path(@enrollment), notice: 'Request was sent!' }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_current_enrollment
      @current_enrollment = current_user.enrollments.current_camp_year_applications.last
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

    # Never trust parameters from the scary internet, only allow the white list through.
    def enrollment_params
      params.require(:enrollment).permit(
                          :user_id, :international, :high_school_name,
                          :high_school_address1, :high_school_address2,
                          :high_school_city, :high_school_state,
                          :high_school_non_us, :high_school_postalcode,
                          :high_school_country, :year_in_school,
                          :anticipated_graduation_year, :room_mate_request,
                          :personal_statement, :shirt_size, :notes,
                          :application_status, :offer_status,
                          :partner_program, :transcript,
                          :student_packet, :campyear,
                          :vaccine_record, :covid_test_record,
                          registration_activity_ids: [],
                          session_registration_ids: [],
                          course_registration_ids: [])
    end
end
