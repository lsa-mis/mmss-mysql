class ApplicantDetailsController < ApplicationController
  devise_group :logged_in, contains: [:user, :admin]
  before_action :authenticate_logged_in!
  before_action :authenticate_admin!, only: [:index, :destroy]
  before_action :set_applicant_detail, only: [:show, :edit, :update, :destroy]


  # GET /applicant_details
  # GET /applicant_details.json
  def index
    @applicant_details = ApplicantDetail.all
  end

  # GET /applicant_details/1
  # GET /applicant_details/1.json
  def show
    @us_citizen = citizen_status
    if current_user.enrollments.current_camp_year_applications.present?
      @current_enrollment = current_user.enrollments.current_camp_year_applications.last
    end
  end

  # GET /applicant_details/new
  def new
    @applicant_detail = ApplicantDetail.new
  end

  # GET /applicant_details/1/edit
  def edit
    if current_user.enrollments.current_camp_year_applications.present?
      @current_enrollment = current_user.enrollments.current_camp_year_applications.last
    end
  end

  # POST /applicant_details
  # POST /applicant_details.json
  def create
    if current_user.applicant_detail.present?
      flash[:notice] = "Applicant Details exist. Click Edit, if you want to change something."
      redirect_to(applicant_detail_path(current_user))
    else
      @applicant_detail = current_user.create_applicant_detail(applicant_detail_params)

      respond_to do |format|
        if @applicant_detail.save
          format.html { redirect_to root_path, notice: 'Applicant detail was successfully created.' }
          format.json { render :show, status: :created, location: @applicant_detail }
        else
          format.html { render :new }
          format.json { render json: @applicant_detail.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PATCH/PUT /applicant_details/1
  # PATCH/PUT /applicant_details/1.json
  def update
    respond_to do |format|
      if @applicant_detail.update(applicant_detail_params)
        format.html { redirect_to root_path, notice: 'Applicant detail was successfully updated.' }
        format.json { render :show, status: :ok, location: @applicant_detail }
      else
        format.html { render :edit }
        format.json { render json: @applicant_detail.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /applicant_details/1
  # DELETE /applicant_details/1.json
  def destroy
    @applicant_detail.destroy
    respond_to do |format|
      format.html { redirect_to applicant_details_url, notice: 'Applicant detail was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_applicant_detail
      @applicant_detail = current_user.applicant_detail
    end

    def citizen_status
      if @applicant_detail.us_citizen
        "You are a US citizen"
      else
        nil 
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def applicant_detail_params
      params.require(:applicant_detail).permit(:user_id, :firstname, :middlename, :lastname, :gender, :us_citizen, :demographic, :birthdate, :diet_restrictions, :shirt_size, :address1, :address2, :city, :state, :state_non_us, :postalcode, :country, :phone, :parentname, :parentaddress1, :parentaddress2, :parentcity, :parentstate, :parentstate_non_us, :parentzip, :parentcountry, :parentphone, :parentworkphone, :parentemail)
    end
end
