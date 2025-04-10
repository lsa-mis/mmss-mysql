class WaitlistedMailerPreview < ActionMailer::Preview
  def app_waitlisted_email
    enrollment = Enrollment.first
    WaitlistedMailer.app_waitlisted_email(enrollment)
  end
end
