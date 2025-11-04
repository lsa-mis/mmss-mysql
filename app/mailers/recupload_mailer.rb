# frozen_string_literal: true

class RecuploadMailer < ApplicationMailer
  def received_email
    @recupload = params[:recupload]
    @recommendation = Recommendation.find(@recupload.recommendation_id)
    @student = @recommendation.enrollment.user.applicant_detail
    @url = root_url
    mail(to: @recommendation.email, subject: "University of Michigan - Michigan Math and Science Scholars: Recommendation for #{@student.firstname} #{@student.lastname}")
  end

  def applicant_received_email
    @url = root_url
    @recupload = params[:recupload]
    @recommendation = Recommendation.find(@recupload.recommendation_id)
    @student_email = @recommendation.enrollment.user.email
    @student = @recommendation.enrollment.user.applicant_detail
    mail(to: @student_email, subject: "University of Michigan - Michigan Math and Science Scholars: Recommendation received for #{@student.firstname} #{@student.lastname}")
  end

end
