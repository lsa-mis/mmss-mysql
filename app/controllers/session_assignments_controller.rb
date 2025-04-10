class SessionAssignmentsController < ApplicationController
  devise_group :logged_in, contains: [:user, :admin]
  before_action :authenticate_logged_in!
  before_action :authenticate_admin!, only: [:index, :destroy]

  before_action :set_session_assignment

  def accept_session_offer
    respond_to do |format|
      if @session_assignment.accept_offer!(current_user)
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
      if @session_assignment.decline_offer!(current_user)
        format.html { redirect_to root_path, notice: 'Session assignment was declined.' }
        format.json { render :show, status: :ok, location: @session_assignment }
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

    def session_assignment_params
      params.require(:session_assignment).permit(:enrollment_id, :camp_occurrence_id)
    end
end
