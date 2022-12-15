class TravelsController < ApplicationController
  devise_group :logged_in, contains: [:user, :admin]
  before_action :authenticate_logged_in!
  before_action :authenticate_admin!, only: [:index, :destroy]
  before_action :set_enrollment
  
  # before_action :set_travel, only: [:show, :edit, :update, :destroy]

  # GET /travels
  # GET /travels.json
  def index
    @travels = Travel.all
  end

  # GET /travels/1
  # GET /travels/1.json
  def show
  end

  # GET /travels/new
  def new
    @travel = @enrollment.travels.new
    @sessions = @enrollment.session_assignments.map { |s| s.camp_occurrence.description_with_start_day }
    Rails.logger.debug "*********************** @sessios #{@enrollment.id}"
  end

  # GET /travels/1/edit
  def edit
  end

  # POST /travels
  # POST /travels.json
  def create
    @travel = Travel.new(travel_params)

    respond_to do |format|
      if @travel.save
        format.html { redirect_to @travel, notice: 'Travel was successfully created.' }
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
    respond_to do |format|
      if @travel.update(travel_params)
        format.html { redirect_to @travel, notice: 'Travel was successfully updated.' }
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
    # Use callbacks to share common setup or constraints between actions.
    # def set_travel
    #   @travel = Travel.find(params[:id])
    # end

    def set_enrollment
      @enrollment = Enrollment.find(params[:enrollment_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def travel_params
      params.require(:travel).permit(:enrollment_id, :direction, :transport_needed, :date, :mode, :carrier, :route_num, :note)
    end
end
