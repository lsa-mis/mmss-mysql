# frozen_string_literal: true

class WaitlistedMailer < ApplicationMailer
  def app_waitlisted_email(enrollment)
    @application = ApplicantDetail.find_by(user_id: enrollment.user)
    @camp_config = CampConfiguration.find_by(active: true)
    mail(to: enrollment.user.email, subject: 'University of Michigan - Michigan Math and Science Scholars: Application Wait-listed')
  end
end
