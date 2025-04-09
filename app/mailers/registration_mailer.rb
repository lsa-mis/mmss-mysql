class RegistrationMailer < ApplicationMailer
  def app_complete_email(user)
    @user_detail = user
    @application = ApplicantDetail.find_by(user_id: user)
    @url = root_url
    @camp_config = CampConfiguration.find_by(active: true)
    mail(to: user.email, subject: "University of Michigan - Michigan Math and Science Scholars: Confirmation of application")
  end

  def app_enrolled_email(user)
    @user_detail = user
    @application = ApplicantDetail.find_by(user_id: user)
    @url = root_url
    @camp_config = CampConfiguration.find_by(active: true)
    # @enrollment = user.enrollments.last
    mail(to: user.email, subject: "University of Michigan - Michigan Math and Science Scholars: Your enrollment in the #{@camp_config.display_name} camp is complete")
  end
end
