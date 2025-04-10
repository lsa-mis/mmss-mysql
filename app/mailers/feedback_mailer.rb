class FeedbackMailer < ApplicationMailer
  def feedback_email
    @url = root_url
    @feedback = params[:feedback]
    @sender = User.find(@feedback.user_id)
    mail(to: 'mmss-support@umich.edu', subject: "Feedback from #{@sender.email}")
  end
end
