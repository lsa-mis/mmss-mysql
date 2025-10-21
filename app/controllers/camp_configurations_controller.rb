# frozen_string_literal: true

class CampConfigurationsController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_camp_configuration, only: [:show, :edit, :update, :destroy]

  # GET /camp_configurations
  # GET /camp_configurations.json
  def index
    @camp_configurations = CampConfiguration.all
  end

  # GET /camp_configurations/1
  # GET /camp_configurations/1.json
  def show
  end

  # GET /camp_configurations/new
  def new
    @camp_configuration = CampConfiguration.new
  end

  # GET /camp_configurations/1/edit
  def edit
  end

  # POST /camp_configurations
  # POST /camp_configurations.json
  def create
    @camp_configuration = CampConfiguration.new(camp_configuration_params)

    respond_to do |format|
      if @camp_configuration.save
        format.html { redirect_to @camp_configuration, notice: 'Camp configuration was successfully created.' }
        format.json { render :show, status: :created, location: @camp_configuration }
      else
        format.html { render :new }
        format.json { render json: @camp_configuration.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /camp_configurations/1
  # PATCH/PUT /camp_configurations/1.json
  def update
    respond_to do |format|
      if @camp_configuration.update(camp_configuration_params)
        format.html { redirect_to @camp_configuration, notice: 'Camp configuration was successfully updated.' }
        format.json { render :show, status: :ok, location: @camp_configuration }
      else
        format.html { render :edit }
        format.json { render json: @camp_configuration.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /camp_configurations/1
  # DELETE /camp_configurations/1.json
  def destroy
    @camp_configuration.destroy
    respond_to do |format|
      format.html { redirect_to camp_configurations_url, notice: 'Camp configuration was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_camp_configuration
      @camp_configuration = CampConfiguration.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def camp_configuration_params
      params.require(:camp_configuration).permit(:camp_year, :application_open, :application_close, :priority, :application_materials_due, :camper_acceptance_due, :active)
    end
end
