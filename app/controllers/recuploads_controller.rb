# frozen_string_literal: true

# Recommenders upload their letter through the link in the request email (no login). The link
# carries the recommendation's random upload token (Recommendation#upload_token): an unknown or
# missing token is a 404, an expired one a 410 with instructions to ask for a new link, and a
# token whose letter has already been received is refused. Everything else about recuploads
# (listing, viewing, editing, deleting) is admin-only and lives in Admin::RecuploadsController.
class RecuploadsController < ApplicationController
  before_action :set_recommendation, only: %i[new create]

  def error
  end

  def success
  end

  def new
    @recupload = @recommendation.build_recupload
  end

  def create
    # Always attach to the recommendation the emailed link resolved to, never to a
    # caller-supplied recommendation_id.
    @recupload = @recommendation.build_recupload(recupload_params)

    if @recupload.save
      RecuploadMailer.with(recupload: @recupload).received_email.deliver_now
      RecuploadMailer.with(recupload: @recupload).applicant_received_email.deliver_now
      redirect_to recupload_success_path, notice: 'Recommendation was successfully uploaded.', status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def set_recommendation
    @recommendation = Recommendation.find_by_upload_token(params[:token])

    if @recommendation.nil?
      Rails.logger.info("Recommender upload link not found (token_present: #{params[:token].present?}, legacy_hash_present: #{params[:hash].present?})")
      flash.now[:alert] = not_found_message
      return render :error, status: :not_found
    end

    if @recommendation.recupload.present?
      return redirect_to recupload_error_path, alert: 'A recommendation has already been submitted for this user'
    end

    if @recommendation.upload_token_expired?
      Rails.logger.info("Recommender upload link expired (recommendation_id: #{@recommendation.id})")
      return render :expired, status: :gone
    end

    @student = @recommendation.applicant_name
  end

  # Links sent before the token change carried a `hash` parameter; tell those recipients why
  # their link stopped working.
  def not_found_message
    if params[:hash].present?
      'This recommendation link is from an older email and no longer works. Please contact MMSS admin for a new link.'
    else
      'We could not find the recommendation request. Please contact MMSS admin for assistance.'
    end
  end

  def recupload_params
    params.require(:recupload).permit(:letter, :authorname, :studentname, :recletter)
  end
end
