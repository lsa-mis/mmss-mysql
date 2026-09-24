# frozen_string_literal: true

# Recommenders upload their letter through the link in the request email (no login). Everything
# else about recuploads (listing, viewing, editing, deleting) is admin-only and lives in
# Admin::RecuploadsController.
class RecuploadsController < ApplicationController
  before_action :get_recommendation, only: %i[new create]

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

  def create
    # Always attach to the recommendation the emailed link resolved to, never to a
    # caller-supplied recommendation_id.
    @recupload = @recommendation.build_recupload(recupload_params)

    respond_to do |format|
      if @recupload.save
        format.html { redirect_to recupload_success_path, notice: 'Recommendation was successfully uploaded.', status: :see_other }
        format.json { render json: { id: @recupload.id }, status: :created }
        RecuploadMailer.with(recupload: @recupload).received_email.deliver_now
        RecuploadMailer.with(recupload: @recupload).applicant_received_email.deliver_now
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @recupload.errors, status: :unprocessable_content }
      end
    end
  end

  private

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
    # Log identifiers only: params carries the recommendation access hash and form fields.
    Rails.logger.error(
      "Error in get_recommendation: #{e.class}: #{e.message} " \
      "(recommendation_id: #{rec_id.inspect}, applicant_detail_id: #{params[:id].inspect}, hash_present: #{params['hash'].present?})"
    )
    redirect_to recupload_error_path,
                alert: 'We could not find the recommendation request. Please contact MMSS admin for assistance.'
  end

  def recupload_params
    params.require(:recupload).permit(:letter, :authorname, :studentname, :recletter)
  end
end
