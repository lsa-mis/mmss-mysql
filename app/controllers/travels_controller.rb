# frozen_string_literal: true

class TravelsController < ApplicationController
  devise_group :logged_in, contains: [:user, :admin]
  before_action :authenticate_logged_in!
  before_action :authenticate_admin!, only: [:index, :destroy]
  before_action :set_current_enrollment
  before_action :set_list_of_sessions, only: [:new, :edit, :create, :update]
  
  # GET /travels
  # GET /travels.json
  def index
    @travels = Travel.all
  end

  # GET /travels/1
  # GET /travels/1.json
  def show
    @travel = @current_enrollment.travels.find(params[:id])
  end

  # GET /travels/new
  def new
    @travel = @current_enrollment.travels.new
  end

  # GET /travels/1/edit
  def edit
    @travel = @current_enrollment.travels.find(params[:id])
  end

  # POST /travels
  # POST /travels.json
  def create
    @travel = @current_enrollment.travels.new(travel_params)
    respond_to do |format|
      if @travel.save
        format.html { redirect_to root_path, notice: 'Travel was successfully created.' }
        format.json { render :show, status: :created, location: @travel }
      else
        format.html { render :new }
        format.json { render json: @travel.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /travels/1
  # PATCH/PUT /travels/1.json
  def update
    @travel = @current_enrollment.travels.find(params[:id])
    respond_to do |format|
      if @travel.update(travel_params)
        format.html { redirect_to root_path, notice: 'Travel was successfully updated.' }
        format.json { render :show, status: :ok, location: @travel }
      else
        format.html { render :edit }
        format.json { render json: @travel.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /travels/1
  # DELETE /travels/1.json
  def destroy
    @travel.destroy
    respond_to do |format|
      format.html { redirect_to travels_url, notice: 'Travel was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

    def set_current_enrollment
      @current_enrollment = Enrollment.find(params[:enrollment_id])
    end

    def set_list_of_sessions
      @sessions = @current_enrollment.session_assignments.map { |s| s.camp_occurrence.description_with_month_and_day }
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def travel_params
      params.require(:travel).permit(:enrollment_id, :arrival_session, :depart_session, 
              :arrival_transport, :arrival_carrier, :arrival_route_num, :arrival_date, :arrival_time, 
              :depart_transport, :depart_carrier, :depart_route_num, :depart_date, :depart_time, :note)
    end
end
