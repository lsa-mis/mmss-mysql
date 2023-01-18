class SessionAssignmentsController < ApplicationController
  devise_group :logged_in, contains: [:user, :admin]
  before_action :authenticate_logged_in!
  before_action :authenticate_admin!, only: [:index, :destroy]
  
  before_action :set_current_enrollment
  before_action :set_session_assignment
  before_action :set_course_assignment

  def accept_session_offer
    respond_to do |format|
      if @session_assignment.update(offer_status: "accepted")
        OfferMailer.offer_accepted_email(current_user, @session_assignment, @course_assignment).deliver_now
        status_array = SessionAssignment.where(enrollment_id: @current_enrollment).pluck(:offer_status)
        if status_array.count("accepted") + status_array.count("declined") == status_array.size
          enroll_id = @session_assignment.enrollment_id
          Enrollment.find(enroll_id).update(offer_status: "accepted", application_status: "offer accepted", application_status_updated_on: Date.today)
        end
        format.html { redirect_to all_payments_path, notice: 'Session assignment was successfully accepted.' }
        format.json { render :show, status: :ok, location: @session_assignment }
      else
        format.html { redirect_to root_path, notice: 'There was a problem processing the offer.' }
        format.json { render json: @session_assignment.errors, status: :unprocessable_entity }
      end
    end
  end

  def decline_session_offer
    respond_to do |format|
      if @session_assignment.update(offer_status: "declined")
        OfferMailer.offer_declined_email(current_user, @session_assignment, @course_assignment).deliver_now
        if @course_assignment.present?
          @course_assignment.destroy
        end
        # destroy wait_list assignments too (if they exist)
        waiting_list = CourseAssignment.find_by(enrollment_id: @session_assignment.enrollment_id, course_id: CampOccurrence.find(@session_assignment.camp_occurrence_id).courses.ids, wait_list: true)
        if waiting_list.present?
          waiting_list.destroy
        end
        status_array = SessionAssignment.where(enrollment_id: @current_enrollment).pluck(:offer_status)
        if status_array.count("declined") == status_array.size
          enroll_id = @session_assignment.enrollment_id
          Enrollment.find(enroll_id).update(offer_status: "declined", application_status: "offer declined", application_status_updated_on: Date.today)
          format.html { redirect_to root_path, notice: 'Session assignment was declined.' }
          format.json { render :show, status: :ok, location: @session_assignment }
        elsif status_array.count("accepted") + status_array.count("declined") == status_array.size
          enroll_id = @session_assignment.enrollment_id
          Enrollment.find(enroll_id).update(offer_status: "accepted", application_status: "offer accepted", application_status_updated_on: Date.today)
          format.html { redirect_to all_payments_path, notice: 'Session assignment was declined.' }
          format.json { render :show, status: :ok, location: @session_assignment }
        else
          format.html { redirect_to root_path, notice: 'Session assignment was declined.' }
          format.json { render :show, status: :ok, location: @session_assignment }
        end

      else
        format.html { redirect_to root_path, notice: 'There was a problem processing the offer.' }
        format.json { render json: @session_assignment.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    def set_session_assignment
      @session_assignment = SessionAssignment.find(params[:id])
    end

    def set_course_assignment
      @course_assignment = CourseAssignment.find_by(enrollment_id: @session_assignment.enrollment_id, course_id: CampOccurrence.find(@session_assignment.camp_occurrence_id).courses.ids, wait_list: false)
    end

    def session_assignment_params
      params.require(:session_assignment).permit(:enrollment_id, :camp_occurrence_id)
    end

    def set_current_enrollment
      @current_enrollment = current_user.enrollments.current_camp_year_applications.last
    end

end
