# frozen_string_literal: true

# Applicants accept or decline their own session offers (links in the progress sidebox). The
# assignment lookup is scoped to the signed-in user's enrollments, so a foreign id is a 404.
class SessionAssignmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session_assignment

  def accept_session_offer
    respond_to do |format|
      if @session_assignment.accept_offer!(current_user)
        format.html { redirect_to all_payments_path, notice: 'Session assignment was successfully accepted.', status: :see_other }
        format.json { render :show, status: :ok, location: @session_assignment }
      else
        format.html { redirect_to root_path, notice: 'There was a problem processing the offer.', status: :see_other }
        format.json { render json: @session_assignment.errors, status: :unprocessable_content }
      end
    end
  end

  def decline_session_offer
    respond_to do |format|
      if @session_assignment.decline_offer!(current_user)
        format.html { redirect_to root_path, notice: 'Session assignment was declined.', status: :see_other }
        format.json { render :show, status: :ok, location: @session_assignment }
      else
        format.html { redirect_to root_path, notice: 'There was a problem processing the offer.', status: :see_other }
        format.json { render json: @session_assignment.errors, status: :unprocessable_content }
      end
    end
  end

  private
    def set_session_assignment
      @session_assignment = SessionAssignment.where(enrollment_id: current_user.enrollments.select(:id)).find(params[:id])
    end
end
