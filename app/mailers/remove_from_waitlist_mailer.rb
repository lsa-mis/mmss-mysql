class RemoveFromWaitlistMailer < ApplicationMailer

  default from: 'University of Michigan MMSS High School Summer Program <mmss@umich.edu>'

  def app_remove_from_waitlist_email
    enrollment = Enrollment.find_by(id: params[:enrollment])
    @application = ApplicantDetail.find_by(user_id: enrollment.user)
    @camp_config = CampConfiguration.find_by(active: true)
    mail(to: enrollment.user.email, subject: "UM MMSS: Application Wait-listed")
  end
end
