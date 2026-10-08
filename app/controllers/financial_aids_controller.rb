# frozen_string_literal: true

# Applicant-facing financial aid request form. Admin listing, awards and deletion live in
# Admin::FinancialAidRequestsController.
class FinancialAidsController < ApplicationController
  before_action :authenticate_user!

  before_action :set_current_enrollment
  before_action :set_financial_aid, only: [:show, :edit, :update]

  # GET /financial_aids/1
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
  def create
    @financial_aid =  @current_enrollment.financial_aids.create(financial_aid_params)

    if @financial_aid.save
      redirect_to all_payments_path, notice: 'Financial aid was successfully created.', status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /financial_aids/1
  def update
    if @financial_aid.update(financial_aid_params)
      redirect_to all_payments_path, notice: 'Financial aid was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  private
    # Every action works on the applicant's current application; without one (no application
    # this camp year) there is nothing to request aid for.
    def set_current_enrollment
      @current_enrollment = current_user.enrollments.current_camp_year_applications.last
      return if @current_enrollment

      redirect_to root_path, alert: 'No current application found for this camp year.', status: :see_other
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_financial_aid
      @financial_aid = @current_enrollment.financial_aids.find(params[:id])
    end

    # The enrollment is always the applicant's current one (set_current_enrollment); never take it
    # from the form. Award fields (amount, source, status, deadline) are admin-only and set through
    # Admin::FinancialAidRequestsController.
    def financial_aid_params
      params.require(:financial_aid).permit(:note, :adjusted_gross_income)
    end
end
