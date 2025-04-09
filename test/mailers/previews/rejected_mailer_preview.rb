class RejectedMailerPreview < ActionMailer::Preview
  def app_rejected_email
    enrollment = Enrollment.first
    RejectedMailer.app_rejected_email(enrollment)
  end
end
