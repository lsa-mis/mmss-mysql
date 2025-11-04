# frozen_string_literal: true

class ActivitiesController < ApplicationController
  before_action :authenticate_admin!, only: [:index, :show, :edit, :update, :destroy]
  before_action :set_activity, only: [:show, :edit, :update, :destroy]

  # GET /activities
  # GET /activities.json
  def index
    @activities = Activity.all.order( :camp_occurrence_id, :date_occurs )
  end

  # GET /activities/1
  # GET /activities/1.json
  def show
  end


  # GET /activities/1/edit
  def edit
  end

  # POST /activities
  # POST /activities.json
  def create
    @camp_occurrence = CampOccurrence.find(params[:camp_occurrence_id])
    @camp_configuration = @camp_occurrence.camp_configuration_id
    @activity = @camp_occurrence.activities.create(activity_params)
    if @activity.errors 
      render :edit
    else 
      redirect_to activities_path, notice: 'Activity was successfully created.'
    end
  end

  # PATCH/PUT /activities/1
  # PATCH/PUT /activities/1.json
  def update
    respond_to do |format|
      if @activity.update(activity_params)
        format.html { redirect_to @activity, notice: 'Activity was successfully updated.' }
        format.json { render :show, status: :ok, location: @activity }
      else
        format.html { render :edit }
        format.json { render json: @activity.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /activities/1
  # DELETE /activities/1.json
  def destroy
    @activity.destroy
    respond_to do |format|
      format.html { redirect_to activities_url, notice: 'Activity was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_activity
      @activity = Activity.find(params[:id])
    end

    def set_camp_occurrence
      @camp_occurrence = CampOccurrence.find(params[:camp_occurrence_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def activity_params
      params.require(:activity).permit(:camp_occurrence_id, :description, :cost_cents, :date_occurs, :active)
    end
end
