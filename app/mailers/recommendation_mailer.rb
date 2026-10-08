# frozen_string_literal: true

class RecommendationMailer < ApplicationMailer
  # The upload link carries only the recommendation's random upload token; the recommender needs
  # no login. Callers must make sure a token has been issued (it is on create, and
  # Recommendation#issue_upload_token! mints a fresh one for "Resend request").
  def request_email
    @recommendation = params[:recommendation]
    raise ArgumentError, 'recommendation has no active upload token' if @recommendation.upload_token.blank?

    @enrollment = Enrollment.find(@recommendation.enrollment_id)
    @student = ApplicantDetail.find_by(user_id: @enrollment.user_id)
    @expires_on = @recommendation.upload_token_expires_at
    @url = new_recupload_url(token: @recommendation.upload_token)

    # Disable Sendgrid click tracking for this email
    headers['X-SMTPAPI'] = '{"filters":{"clicktrack":{"settings":{"enable":0}}}}'

    mail(to: @recommendation.email,
         subject: "University of Michigan - Michigan Math and Science Scholars: Recommendation Request for #{@student.firstname} #{@student.lastname}")
  end
end
