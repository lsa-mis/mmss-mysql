class SessionAssignmentsController < InheritedResources::Base

  def accept_session_offer
    @session_assignment = SessionAssignment.find(params[:id])
    respond_to do |format|
      if @session_assignment.update(offer_status: "accepted")
        format.html { redirect_to all_payments_path, notice: 'Session assignment was successfully accepted.' }
        format.json { render :show, status: :ok, location: @session_assignment }
      else
        format.html { redirect_to root_path, notice: 'There was a problem processing the offer.' }
        format.json { render json: @session_assignment.errors, status: :unprocessable_entity }
      end
    end
  end

  def decline_session_offer
    @session_assignment = SessionAssignment.find(params[:id])
    respond_to do |format|
      if @session_assignment.update(offer_status: "declined")
        session_id = @session_assignment.camp_occurrence_id
        session_courses_ids = CampOccurrence.find(session_id).courses.pluck(:id)
        if CourseAssignment.where(enrollment_id: current_enrollment, course_id: session_courses_ids).exists?
          CourseAssignment.where(enrollment_id: current_enrollment, course_id: session_courses_ids).destroy_all
        end
        format.html { redirect_to all_payments_path, notice: 'Session assignment was successfully accepted.' }
        format.json { render :show, status: :ok, location: @session_assignment }
      else
        format.html { redirect_to root_path, notice: 'There was a problem processing the offer.' }
        format.json { render json: @session_assignment.errors, status: :unprocessable_entity }
      end
    end
  end

  private

    def session_assignment_params
      params.require(:session_assignment).permit(:enrollment_id, :camp_occurrence_id)
    end

    # def set_session_assignment
    #   @session_assignment = SessionAssignment.where(enrollment_id: current_enrollment)
    # end

    def current_enrollment
      @current_enrollment = current_user.enrollments.last
    end

end
