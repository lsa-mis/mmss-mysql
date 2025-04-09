class RecommendationMailer < ApplicationMailer
  def request_email
    @recommendation = params[:recommendation]
    @enrollment = Enrollment.find(@recommendation.enrollment_id)
    @student = ApplicantDetail.find_by(user_id: @enrollment.user_id)
    @hashval = "nGklDoc2egIkzFxr0U#{@recommendation.id}" # sha256_hash
    @url = "#{ConstantData::HOST_URL}/recuploads/new?id=#{@student.id}&yr=#{CampConfiguration.active_camp_year}&email=#{@recommendation.email}&hash=#{@hashval}"

    # Disable Sendgrid click tracking for this email
    headers['X-SMTPAPI'] = '{"filters":{"clicktrack":{"settings":{"enable":0}}}}'

    mail(to: @recommendation.email,
         subject: "University of Michigan - Michigan Math and Science Scholars: Recommendation Request for #{@student.firstname} #{@student.lastname}")
  end
end
