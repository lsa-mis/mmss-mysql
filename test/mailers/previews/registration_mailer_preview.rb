class RegistrationMailerPreview < ActionMailer::Preview
  def app_complete_email
    user = User.first
    RegistrationMailer.app_complete_email(user)
  end

  def app_enrolled_email
    user = User.first
    RegistrationMailer.app_enrolled_email(user)
  end
end
