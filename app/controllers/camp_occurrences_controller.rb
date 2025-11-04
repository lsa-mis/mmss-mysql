# frozen_string_literal: true

class CampOccurrencesController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_camp_configuration, only: [:show, :edit, :update, :destroy]
  before_action :set_camp_occurrence, only: [:show, :edit, :update, :destroy]


  # GET /camp_occurrences/1
  # GET /camp_occurrences/1.json
  def show
  end

  # GET /camp_occurrences/1/edit
  def edit
  end

  # POST /camp_occurrences
  # POST /camp_occurrences.json
  def create
    @camp_configuration = CampConfiguration.find(params[:camp_configuration_id])
    @camp_occurrence = @camp_configuration.camp_occurrences.create(camp_occurrence_params)
    redirect_to camp_configuration_path(@camp_configuration)
  end

  # PATCH/PUT /occurrences/1
  # PATCH/PUT /occurrences/1.json
  def update
    respond_to do |format|
      if @camp_occurrence.update(camp_occurrence_params)
        format.html { redirect_to @camp_configuration, notice: 'Camp Occurrence was successfully updated.' }
        format.json { render :show, status: :ok, location: @camp_occurrence }
      else
        format.html { render :edit }
        format.json { render json: @camp_occurrence.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /occurrences/1
  # DELETE /occurrences/1.json
  def destroy
    @camp_occurrence.destroy
    respond_to do |format|
      format.html { redirect_to @camp_configuration, notice: 'Camp Occurrence was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_camp_occurrence
      @camp_occurrence = CampOccurrence.find(params[:id])
    end

    def set_camp_configuration
      @camp_configuration = CampConfiguration.find(params[:camp_configuration_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def camp_occurrence_params
      params.require(:camp_occurrence).permit(:camp_configuration_id, :description, :begin_date, :end_date, :active)
    end
end
