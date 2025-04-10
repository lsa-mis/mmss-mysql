class RejectedMailer < ApplicationMailer
  def app_rejected_email(enrollment)
    @application = ApplicantDetail.find_by(user_id: enrollment.user)
    rejection = Rejection.find_by(enrollment_id: enrollment)
    @reason = rejection&.reason || "No specific reason provided"
    @camp_config = CampConfiguration.find_by(active: true)
    mail(to: enrollment.user.email, subject: 'University of Michigan - Michigan Math and Science Scholars: Application Rejected')
  end
end
