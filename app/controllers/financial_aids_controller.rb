# frozen_string_literal: true

# Applicant-facing financial aid request form. Admin listing, awards and deletion live in
# Admin::FinancialAidRequestsController.
class FinancialAidsController < ApplicationController
  devise_group :logged_in, contains: [:user, :admin]
  before_action :authenticate_logged_in!

  before_action :set_current_enrollment
  before_action :set_financial_aid, only: [:show, :edit, :update]

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
        format.html { redirect_to all_payments_path, notice: 'Financial aid was successfully created.', status: :see_other }
        format.json { render :show, status: :created, location: @financial_aid }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @financial_aid.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /financial_aids/1
  # PATCH/PUT /financial_aids/1.json
  def update
    respond_to do |format|
      if @financial_aid.update(financial_aid_params)
        format.html { redirect_to all_payments_path, notice: 'Financial aid was successfully updated.', status: :see_other }
        format.json { render :show, status: :ok, location: @financial_aid }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @financial_aid.errors, status: :unprocessable_content }
      end
    end
  end

  private
    # Every action works on the applicant's current application; without one (no application
    # this camp year, or an admin-only session) there is nothing to request aid for.
    def set_current_enrollment
      @current_enrollment = current_user&.enrollments&.current_camp_year_applications&.last
      return if @current_enrollment

      redirect_to root_path, alert: 'No current application found for this camp year.', status: :see_other
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_financial_aid
      @financial_aid = @current_enrollment.financial_aids.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def financial_aid_params
      # The enrollment is always the applicant's current one (set_current_enrollment); never take it from the form.
      permitted = [:note, :adjusted_gross_income]

      # Only allow admin-only fields if user is an admin
      if admin_signed_in?
        permitted += [:amount_cents, :source, :status, :payments_deadline]
      end

      params.require(:financial_aid).permit(*permitted)
    end
end
