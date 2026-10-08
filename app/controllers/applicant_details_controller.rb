# frozen_string_literal: true

##
# Applicant-facing applicant details (one record per account, owned by the signed-in user). The
# admin listing lives in Admin::ApplicantDetailsController; applicant details are never destroyed.
class ApplicantDetailsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_applicant_detail, only: %i[show edit update]

  # GET /applicant_details/1
  def show
    @us_citizen = citizen_status
    return unless current_user.enrollments.current_camp_year_applications.present?

    @current_enrollment = current_user.enrollments.current_camp_year_applications.last
  end

  # GET /applicant_details/new
  def new
    @applicant_detail = ApplicantDetail.new
  end

  # GET /applicant_details/1/edit
  def edit
    return unless current_user.enrollments.current_camp_year_applications.present?

    @current_enrollment = current_user.enrollments.current_camp_year_applications.last
  end

  # POST /applicant_details
  def create
    if current_user.applicant_detail.present?
      flash[:notice] = 'Applicant Details exist. Click Edit, if you want to change something.'
      redirect_to(applicant_detail_path(current_user), status: :see_other)
    else
      @applicant_detail = current_user.create_applicant_detail(applicant_detail_params)

      if @applicant_detail.save
        redirect_to root_path, notice: 'Applicant detail was successfully created.', status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end
  end

  # PATCH/PUT /applicant_details/1
  def update
    if @applicant_detail.update(applicant_detail_params)
      redirect_to root_path, notice: 'Applicant detail was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  # The record is always the signed-in applicant's own (the :id in the URL is not looked up);
  # without one there is nothing to show or edit yet.
  def set_applicant_detail
    @applicant_detail = current_user&.applicant_detail
    return if @applicant_detail

    redirect_to new_applicant_detail_path, alert: 'Please fill in your applicant details first.', status: :see_other
  end

  def citizen_status
    'You are a US citizen' if @applicant_detail.us_citizen
  end

  # The owner is always current_user (create_applicant_detail sets it); user_id is never taken
  # from the form, so an applicant cannot re-home the record to another account on update.
  def applicant_detail_params
    params.require(:applicant_detail).permit(
      :firstname, :middlename, :lastname, :gender, :us_citizen,
      :demographic_id, :demographic_other, :birthdate, :diet_restrictions,
      :shirt_size, :address1, :address2, :city, :state, :state_non_us,
      :postalcode, :country, :phone, :parentname, :parentaddress1, :parentaddress2,
      :parentcity, :parentstate, :parentstate_non_us, :parentzip, :parentcountry,
      :parentphone, :parentworkphone, :parentemail
    )
  end
end
