# frozen_string_literal: true

class FinancialAidsController < ApplicationController
  devise_group :logged_in, contains: [:user, :admin]
  before_action :authenticate_logged_in!
  before_action :authenticate_admin!, only: [:index, :destroy]

  before_action :set_current_enrollment
  before_action :set_financial_aid, only: [:show, :edit, :update, :destroy]

  # GET /financial_aids
  # GET /financial_aids.json
  def index
    if admin_signed_in?
      @financial_aids = FinancialAid.all
    else
      @financial_aids = FinancialAid.where(enrollment_id: @current_enrollment)
    end
  end

  # GET /financial_aids/1
  # GET /financial_aids/1.json
  def show
    @financial_aids = FinancialAid.where(enrollment_id: @current_enrollment)
  end

  # GET /financial_aids/new
  def new
    @financial_aid = FinancialAid.new
  end

  # GET /financial_aids/1/edit
  def edit
  end

  # POST /financial_aids
  # POST /financial_aids.json
  def create
    @financial_aid =  @current_enrollment.financial_aids.create(financial_aid_params)

    respond_to do |format|
      if @financial_aid.save
        format.html { redirect_to all_payments_path, notice: 'Financial aid was successfully created.' }
        format.json { render :show, status: :created, location: @financial_aid }
      else
        format.html { render :new }
        format.json { render json: @financial_aid.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /financial_aids/1
  # PATCH/PUT /financial_aids/1.json
  def update
    respond_to do |format|
      if @financial_aid.update(financial_aid_params)
        format.html { redirect_to payments_path, notice: 'Financial aid was successfully updated.' }
        format.json { render :show, status: :ok, location: @financial_aid }
      else
        format.html { render :edit }
        format.json { render json: @financial_aid.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /financial_aids/1
  # DELETE /financial_aids/1.json
  def destroy
    @financial_aid.destroy
    respond_to do |format|
      format.html { redirect_to financial_aids_url, notice: 'Financial aid was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    def set_current_enrollment
      @current_enrollment = current_user.enrollments.current_camp_year_applications.last
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_financial_aid
      if admin_signed_in?
        @financial_aid = FinancialAid.find(params[:id])
      else
        @financial_aid = @current_enrollment.financial_aids.find(params[:id])
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def financial_aid_params
      permitted = [:enrollment_id, :note, :adjusted_gross_income]

      # Only allow admin-only fields if user is an admin
      if admin_signed_in?
        permitted += [:amount_cents, :source, :status, :payments_deadline]
      end

      params.require(:financial_aid).permit(*permitted)
    end
end
