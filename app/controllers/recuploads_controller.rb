# frozen_string_literal: true

class RecuploadsController < InheritedResources::Base
  # devise_group :logged_in, contains: [:user, :admin]
  # before_action :authenticate_logged_in!
  # before_action :authenticate_admin!, only: [:index, :destroy]

  before_action :authenticate_admin!, except: %i[success error new create]
  before_action :set_recupload, only: %i[show edit update destroy]
  before_action :get_recommendation, only: %i[new create]

  def index
    redirect_to root_path unless admin_signed_in?
  end

  def show
  end

  def error
  end

  def success
  end

  def new
    if @recommendation.recupload.present?
      redirect_to recupload_error_path, alert: 'A recommendation has already been submitted for this user'
    else
      @recupload = @recommendation.build_recupload
    end
  end

  def edit
  end

  def create
    @recupload = Recupload.new(recupload_params)

    respond_to do |format|
      if @recupload.save
        format.html { redirect_to recupload_success_path, notice: 'Recommendation was successfully uploaded.' }
        format.json { render :show, status: :created, location: @recupload }
        RecuploadMailer.with(recupload: @recupload).received_email.deliver_now
        RecuploadMailer.with(recupload: @recupload).applicant_received_email.deliver_now
      else
        @student = ApplicantDetail.find(params[:id]).full_name if params[:id]
        @recommendation = Recommendation.find(@recupload.recommendation_id) if @recupload.recommendation_id
        format.html { render :new }
        format.json { render json: @recupload.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
  end

  def destroy
    @recupload.destroy
    respond_to do |format|
      format.html { redirect_to recuploads_url, notice: 'Recommendation was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def set_recupload
    @recupload = Recupload.find(params[:id])
  end

  def get_recommendation
    hash_val = params['hash']

    # More robust parsing - look for the pattern anywhere in the hash
    if hash_val && hash_val.include?('nGklDoc2egIkzFxr0U')
      rec_id = hash_val.split('nGklDoc2egIkzFxr0U').last.to_i
    elsif hash_val
      # Try to extract just the numeric part at the end if the pattern isn't found
      rec_id = hash_val.gsub(/[^0-9]/, '').to_i
    else
      raise 'Missing hash parameter'
    end

    @recommendation = Recommendation.find(rec_id)

    # Find the student's name
    if params[:id].present?
      begin
        @student = ApplicantDetail.find(params[:id]).full_name
      rescue ActiveRecord::RecordNotFound
        # If we can't find the ApplicantDetail, try to get the name from the recommendation
        @student = @recommendation.applicant_name
      end
    else
      @student = @recommendation.applicant_name
    end
  rescue StandardError => e
    # Log the error
    Rails.logger.error("Error in get_recommendation: #{e.message}, params: #{params.inspect}")
    redirect_to recupload_error_path,
                alert: 'We could not find the recommendation request. Please contact MMSS admin for assistance.'
  end

  def recupload_params
    params.require(:recupload).permit(:letter, :authorname, :studentname, :recommendation_id, :rechash, :recletter)
  end
end
