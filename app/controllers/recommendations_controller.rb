# frozen_string_literal: true

# Applicants request a recommendation for their own application. Every lookup is scoped to the
# signed-in user's enrollments (a foreign recommendation or enrollment id is a 404) and the
# enrollment a recommendation is created for is always one of the user's own. Listing, deleting
# and the "resend request" mail are admin-only and live in Admin::RecommendationsController.
class RecommendationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_current_enrollment
  before_action :set_recommendation, only: %i[show edit update]

  # GET /recommendations/1
  # GET /recommendations/1.json
  def show
  end

  # GET /enrollments/:enrollment_id/recommendations/new
  def new
    @enrollment = owned_enrollment
    if @enrollment.recommendation.present?
      redirect_to root_path
    else
      @recommendation = @enrollment.build_recommendation
    end
  end

  # GET /recommendations/1/edit
  def edit
    return unless @recommendation.recupload.present?

    redirect_to root_path
  end

  # POST /enrollments/:enrollment_id/recommendations
  # POST /enrollments/:enrollment_id/recommendations.json
  def create
    @enrollment = owned_enrollment
    @recommendation = @enrollment.build_recommendation(recommendation_params)

    respond_to do |format|
      if @recommendation.save
        format.html { redirect_to root_path, notice: 'Recommendation was successfully created and the email was sent.', status: :see_other }
        format.json { render :show, status: :created, location: @recommendation }
        RecommendationMailer.with(recommendation: @recommendation).request_email.deliver_now
        unless @enrollment.application_fee_required
          RegistrationMailer.app_complete_email(current_user).deliver_now
          @enrollment.transition_application_status!('submitted')
        end
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @recommendation.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /recommendations/1
  # PATCH/PUT /recommendations/1.json
  def update
    respond_to do |format|
      if @recommendation.update(recommendation_params)
        format.html { redirect_to @recommendation, notice: 'Recommendation was successfully updated.', status: :see_other }
        format.json { render :show, status: :ok, location: @recommendation }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @recommendation.errors, status: :unprocessable_content }
      end
    end
  end

  private

  def set_current_enrollment
    @current_enrollment = current_user.enrollments.current_camp_year_applications.last
  end

  # The enrollment from the nested route, or the user's current application; never someone
  # else's (RecordNotFound -> 404).
  def owned_enrollment
    if params[:enrollment_id].present?
      current_user.enrollments.find(params[:enrollment_id])
    else
      @current_enrollment || raise(ActiveRecord::RecordNotFound, 'No current application')
    end
  end

  # Nested routes constrain the lookup to the routed (owned) enrollment; top-level routes to any
  # of the user's enrollments.
  def set_recommendation
    enrollment_ids = params[:enrollment_id].present? ? owned_enrollment.id : current_user.enrollments.select(:id)
    @recommendation = Recommendation.where(enrollment_id: enrollment_ids).find(params[:id])
  end

  # enrollment_id comes from the route (owned by current_user), never from the form.
  def recommendation_params
    params.require(:recommendation).permit(:email, :lastname, :firstname, :organization, :address1, :address2, :city,
                                           :state, :state_non_us, :postalcode, :country, :phone_number, :best_contact_time)
  end
end
