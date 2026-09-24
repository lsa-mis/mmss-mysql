# frozen_string_literal: true

# Applicants enter their own travel details (nested under their enrollment). Every lookup is
# scoped to the signed-in user's enrollments, so a foreign enrollment or travel id is a 404.
# Listing and deleting travel records is admin-only and lives in Admin::TravelsController.
class TravelsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_current_enrollment
  before_action :set_travel, only: %i[show edit update]
  before_action :set_list_of_sessions, only: %i[new edit create update]

  # GET /enrollments/:enrollment_id/travels/1
  def show; end

  # GET /enrollments/:enrollment_id/travels/new
  def new
    @travel = @current_enrollment.travels.new
  end

  # GET /enrollments/:enrollment_id/travels/1/edit
  def edit; end

  # POST /enrollments/:enrollment_id/travels
  def create
    @travel = @current_enrollment.travels.new(travel_params)
    respond_to do |format|
      if @travel.save
        format.html { redirect_to root_path, notice: 'Travel was successfully created.', status: :see_other }
        format.json { render :show, status: :created, location: @travel }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @travel.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /enrollments/:enrollment_id/travels/1
  def update
    respond_to do |format|
      if @travel.update(travel_params)
        format.html { redirect_to root_path, notice: 'Travel was successfully updated.', status: :see_other }
        format.json { render :show, status: :ok, location: @travel }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @travel.errors, status: :unprocessable_content }
      end
    end
  end

  private

  def set_current_enrollment
    @current_enrollment = current_user.enrollments.find(params[:enrollment_id])
  end

  def set_travel
    @travel = @current_enrollment.travels.find(params[:id])
  end

  def set_list_of_sessions
    @sessions = @current_enrollment.session_assignments.map { |s| s.camp_occurrence.description_with_month_and_day }
  end

  # enrollment_id comes from the route (and is owned by current_user), never from the form.
  def travel_params
    params.require(:travel).permit(:arrival_session, :depart_session,
                                   :arrival_transport, :arrival_carrier, :arrival_route_num, :arrival_date, :arrival_time,
                                   :depart_transport, :depart_carrier, :depart_route_num, :depart_date, :depart_time, :note)
  end
end
